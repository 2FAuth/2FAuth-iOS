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

struct PinFailedAttempt {
    private(set) var failCount: UInt
    private(set) var timestamp: TimeInterval?

    static func initial() -> Self {
        PinFailedAttempt(failCount: 0, timestamp: .infinity)
    }

    func next(timestamp: TimeInterval?) -> Self {
        PinFailedAttempt(failCount: failCount + 1, timestamp: timestamp)
    }

    func update(timestamp: TimeInterval?) -> Self {
        PinFailedAttempt(failCount: failCount, timestamp: timestamp)
    }
}

struct PinAttemptsConfiguration {
    private(set) var allowedFailCount: UInt
    private(set) var maxFailCount: UInt
    private(set) var waitTimeByAttempt: [UInt: TimeInterval]
    private(set) var fallbackWaitTime: TimeInterval

    static func passcodeProduction() -> Self {
        PinAttemptsConfiguration(allowedFailCount: 5,
                                 maxFailCount: 10,
                                 waitTimeByAttempt: [
                                     6: 1 * 60.0,
                                     7: 5 * 60.0,
                                     8: 15 * 60.0,
                                     9: 60 * 60.0,
                                 ],
                                 fallbackWaitTime: 0)
    }

    static func cloudProduction() -> Self {
        PinAttemptsConfiguration(allowedFailCount: 5,
                                 maxFailCount: 100,
                                 waitTimeByAttempt: [:],
                                 fallbackWaitTime: 60)
    }

    #if DEBUG
        static func passcodeDebug() -> Self {
            PinAttemptsConfiguration(allowedFailCount: 3,
                                     maxFailCount: 7,
                                     waitTimeByAttempt: [
                                         4: 2,
                                         5: 3,
                                         6: 4,
                                     ],
                                     fallbackWaitTime: 0)
        }

        static func cloudDebug() -> Self {
            PinAttemptsConfiguration(allowedFailCount: 3,
                                     maxFailCount: 7,
                                     waitTimeByAttempt: [:],
                                     fallbackWaitTime: 2)
        }
    #endif /* DEBUG */
}
