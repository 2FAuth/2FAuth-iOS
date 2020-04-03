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

enum PinLockDown: Equatable {
    case timer(TimeInterval)
    case noSecureTime
    case forever

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.timer(l), .timer(r)):
            return l == r
        case (.noSecureTime, .noSecureTime):
            return true
        case (.forever, .forever):
            return true
        default:
            return false
        }
    }
}

enum PinManagerError: LocalizedError {
    case operationNotAllowed

    var errorDescription: String? {
        switch self {
        case .operationNotAllowed:
            return LocalizedStrings.operationNotAllowed
        }
    }
}

protocol PinManager: AnyObject {
    var pin: Pin? { get }

    func save(newPin: Pin) throws
    func deletePin() throws

    func attemptsLeft() -> UInt?
    func status() -> PinLockDown?
    func check(_ inputPin: String) -> Bool
}

extension PinManager {
    var hasPin: Bool {
        pin != nil
    }
}
