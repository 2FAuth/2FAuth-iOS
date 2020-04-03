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

final class PinKeychain {
    enum Error: Swift.Error {
        case invalidPin
    }

    private let keychain: KeychainWrapper
    private let pinKey = "pin"
    private let attemptKey = "attempt"

    init(domain: String) {
        keychain = KeychainWrapper(service: AppDomain + ".pin." + domain)
    }

    // MARK: Pin

    func pin() throws -> Pin? {
        let keychainData = try keychain.item(with: pinKey)

        if let keychainDictionary = keychainData,
            let valueData = keychainDictionary[kSecValueData as String] as? Data,
            let optionData = keychainDictionary[kSecAttrGeneric as String] as? Data {
            guard let value = String(data: valueData),
                let optionValue = Int(data: optionData),
                let option = PinOption(rawValue: optionValue) else {
                throw Error.invalidPin
            }
            return Pin(value: value, option: option)
        }

        return nil
    }

    func save(pin: Pin) throws {
        let valueData = pin.value.data
        let optionData = pin.option.rawValue.data
        let attributes = [
            kSecValueData as String: valueData as NSData,
            kSecAttrGeneric as String: optionData as NSData,
        ]

        try keychain.addOrUpdateItem(with: pinKey, attributes: attributes)
    }

    func deletePin() throws {
        try keychain.deleteItem(with: pinKey)
    }

    // MARK: Failed Attempt

    func failedAttempt(fallbackFailCount: UInt, fallbackTimestamp: TimeInterval?) -> PinFailedAttempt {
        do {
            let keychainData = try keychain.item(with: attemptKey)

            if let keychainDictionary = keychainData,
                let failCountData = keychainDictionary[kSecValueData as String] as? Data {
                let failCount = UInt(data: failCountData) ?? fallbackFailCount

                var timestamp = fallbackTimestamp
                if let timestampData = keychainDictionary[kSecAttrGeneric as String] as? Data {
                    timestamp = TimeInterval(data: timestampData) ?? fallbackTimestamp
                }

                return PinFailedAttempt(failCount: failCount, timestamp: timestamp)
            }
        }
        catch {
            os_log("Failed to read pin: '%{public}@'", log: .default, type: .debug, String(describing: error))
            return PinFailedAttempt(failCount: fallbackFailCount, timestamp: fallbackTimestamp)
        }

        return .initial()
    }

    func save(failedAttempt: PinFailedAttempt) throws {
        let failCountData = failedAttempt.failCount.data
        let timestampData = failedAttempt.timestamp?.data

        var attributes = [
            kSecValueData as String: failCountData as NSData,
        ]
        attributes[kSecAttrGeneric as String] = timestampData as NSData?

        try keychain.addOrUpdateItem(with: attemptKey, attributes: attributes)
    }

    func deleteFailedAttempt() throws {
        try keychain.deleteItem(with: attemptKey)
    }
}
