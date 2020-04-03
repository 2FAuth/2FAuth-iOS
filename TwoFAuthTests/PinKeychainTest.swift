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

@testable import TwoFAuth

import XCTest

extension PinFailedAttempt: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.failCount == rhs.failCount && lhs.timestamp == rhs.timestamp
    }
}

class PinKeychainTest: XCTestCase {
    var keychain: PinKeychain!

    override func setUp() {
        super.setUp()

        let randomDomain = UUID().uuidString
        keychain = PinKeychain(domain: randomDomain)
    }

    override func tearDown() {
        super.tearDown()

        XCTAssertNoThrow(try keychain.deletePin())
        XCTAssertNoThrow(try keychain.deleteFailedAttempt())
    }

    func testPinOperations() throws {
        let emptyPin = try keychain.pin()
        XCTAssertNil(emptyPin)

        let pin = Pin(value: "1234", option: .fourDigits)
        XCTAssertNoThrow(try keychain.save(pin: pin))
        let savedPin = try keychain.pin()
        XCTAssertEqual(pin, savedPin)

        XCTAssertNoThrow(try keychain.deletePin())
        let currentEmptyPin = try keychain.pin()
        XCTAssertNil(currentEmptyPin)
    }

    func testFailedAttemptOperations() throws {
        let initial = keychain.failedAttempt(fallbackFailCount: 10, fallbackTimestamp: 100)
        XCTAssertEqual(initial, PinFailedAttempt.initial())

        let fa = PinFailedAttempt(failCount: 2, timestamp: 10)
        XCTAssertNoThrow(try keychain.save(failedAttempt: fa))
        let savedFa = keychain.failedAttempt(fallbackFailCount: 10, fallbackTimestamp: 100)
        XCTAssertEqual(fa, savedFa)

        XCTAssertNoThrow(try keychain.deleteFailedAttempt())
        XCTAssertEqual(keychain.failedAttempt(fallbackFailCount: 10, fallbackTimestamp: 100),
                       PinFailedAttempt.initial())
    }
}
