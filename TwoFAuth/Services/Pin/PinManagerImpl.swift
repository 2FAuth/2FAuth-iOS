//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Andrew Podkovyrin. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import os.log

final class PinManagerImpl: PinManager {
    private(set) var pin: Pin?

    private let keychain: PinKeychain
    private let secureTime: SecureTime
    private let configuration: PinAttemptsConfiguration
    private var failedAttempt: PinFailedAttempt
    private var failedPins = Set<String>()
    private let log = OSLog(subsystem: AppDomain, category: String(describing: PinManagerImpl.self))

    private var waitTime: TimeInterval {
        configuration.waitTimeByAttempt[failedAttempt.failCount] ?? configuration.fallbackWaitTime
    }

    init(keychain: PinKeychain, secureTime: SecureTime, configuration: PinAttemptsConfiguration) throws {
        assert(configuration.maxFailCount > 0)
        assert(configuration.allowedFailCount <= configuration.maxFailCount)

        self.keychain = keychain
        self.secureTime = secureTime
        self.configuration = configuration

        pin = try keychain.pin()
        failedAttempt = keychain.failedAttempt(fallbackFailCount: configuration.maxFailCount - 1,
                                               fallbackTimestamp: secureTime.timestamp)
    }

    func save(newPin: Pin) throws {
        guard failedAttempt.failCount == 0 else {
            throw PinManagerError.operationNotAllowed
        }

        try keychain.save(pin: newPin)
        pin = newPin
    }

    func deletePin() throws {
        guard failedAttempt.failCount == 0 else {
            throw PinManagerError.operationNotAllowed
        }

        try keychain.deletePin()
        pin = nil
    }

    func attemptsLeft() -> UInt? {
        if failedAttempt.failCount <= configuration.allowedFailCount {
            return nil
        }

        return configuration.maxFailCount - failedAttempt.failCount
    }

    func status() -> PinLockDown? {
        if failedAttempt.failCount >= configuration.maxFailCount {
            return .forever
        }

        if waitTime == 0 {
            return nil
        }

        // We must have a secure time in order to calculate the left time
        guard let now = secureTime.timestamp else {
            return .noSecureTime
        }

        // There was not secure time available at the point of locking down, provide it now
        if failedAttempt.timestamp == nil {
            failedAttempt = failedAttempt.update(timestamp: now)
        }
        // this is safe since we've provided timestamp right before
        let lockdownTimestamp = failedAttempt.timestamp!

        let timeInterval = lockdownTimestamp - now + waitTime
        if timeInterval <= 0 {
            // lockdown time has passed
            return nil
        }
        return .timer(timeInterval)
    }

    func check(_ inputPin: String) -> Bool {
        if status() != nil {
            os_log("Check is not allowed, use status() before calling this method", log: log, type: .error)
            return false
        }

        guard let pin = pin else {
            os_log("Inconsistent state: pin is not set", log: log, type: .error)
            return false
        }

        let success = pin.value == inputPin
        if success {
            failedPins = Set<String>()
            failedAttempt = .initial()
        }
        else {
            // don't count current attempt if there is no wait time for the next
            // and the same pin was entered before, during this round of zero-wait attempts
            if waitTime == 0 {
                if failedPins.contains(inputPin) {
                    failedAttempt = failedAttempt.update(timestamp: secureTime.timestamp)
                }
                else {
                    failedPins.insert(inputPin)
                    failedAttempt = failedAttempt.next(timestamp: secureTime.timestamp)
                }
            }
            else {
                failedPins = Set<String>()
                failedAttempt = failedAttempt.next(timestamp: secureTime.timestamp)
            }
        }
        do {
            try keychain.save(failedAttempt: failedAttempt)
        }
        catch {
            os_log("Failed to save failed pin attempt: '%{public}@'", log: log, type: .debug, String(describing: error))
        }

        return success
    }
}
