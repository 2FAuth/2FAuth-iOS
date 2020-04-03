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

class SecureTimeStub: SecureTime {
    var timestamp: TimeInterval?

    func tick() {
        timestamp = (timestamp ?? 0) + 1
    }
}

class PinManagerImplTests: XCTestCase {
    var keychain: PinKeychain!
    var configuration: PinAttemptsConfiguration!

    override func setUp() {
        super.setUp()

        let randomDomain = UUID().uuidString
        keychain = PinKeychain(domain: randomDomain)

        configuration = PinAttemptsConfiguration(allowedFailCount: 2,
                                                 maxFailCount: 5,
                                                 waitTimeByAttempt: [
                                                     3: 10,
                                                     4: 20,
                                                 ],
                                                 fallbackWaitTime: 0)
    }

    override func tearDown() {
        super.tearDown()

        XCTAssertNoThrow(try keychain.deletePin())
        XCTAssertNoThrow(try keychain.deleteFailedAttempt())
    }

    func testSavingAndDeletingPin() throws {
        let manager = try PinManagerImpl(keychain: keychain,
                                         secureTime: SecureTimeStub(),
                                         configuration: configuration)
        XCTAssertFalse(manager.hasPin)
        XCTAssertNil(manager.status())

        let pin = Pin(value: "1234", option: .fourDigits)
        XCTAssertNoThrow(try manager.save(newPin: pin))
        XCTAssert(manager.hasPin)
        XCTAssertEqual(manager.pin, pin)
        var savedPin = try keychain.pin()
        XCTAssertEqual(savedPin, pin)

        XCTAssertNoThrow(try manager.deletePin())
        XCTAssertFalse(manager.hasPin)
        XCTAssertNil(manager.pin)
        savedPin = try keychain.pin()
        XCTAssertNil(savedPin)
    }

    func testCheckingPinWithoutSecureTime() throws {
        let secureTime = SecureTimeStub()
        let manager = try PinManagerImpl(keychain: keychain,
                                         secureTime: secureTime,
                                         configuration: configuration)
        let pin = Pin(value: "1234", option: .fourDigits)
        XCTAssertNoThrow(try manager.save(newPin: pin))

        XCTAssertTrue(manager.check("1234"))
        XCTAssertNil(manager.status())
        XCTAssertNil(manager.attemptsLeft())

        XCTAssertFalse(manager.check("1111"))
        XCTAssertNil(manager.status())
        XCTAssertNil(manager.attemptsLeft())

        // second attempt of the same pin
        XCTAssertFalse(manager.check("1111"))
        XCTAssertNil(manager.status())
        XCTAssertNil(manager.attemptsLeft())

        XCTAssertFalse(manager.check("2222"))
        XCTAssertNil(manager.status())
        XCTAssertNil(manager.attemptsLeft())

        XCTAssertFalse(manager.check("2222"))
        XCTAssertNil(manager.status())
        XCTAssertNil(manager.attemptsLeft())

        XCTAssertFalse(manager.check("3333"))
        XCTAssertEqual(manager.status(), PinLockDown.noSecureTime)
        XCTAssertEqual(manager.attemptsLeft(), configuration.maxFailCount - 3)

        secureTime.tick()
        let status = manager.status()
        let wait = configuration.waitTimeByAttempt[3]!
        XCTAssertEqual(status, PinLockDown.timer(wait))

        secureTime.timestamp = wait + 1
        XCTAssertNil(manager.status())
        XCTAssert(manager.check("1234"))
        XCTAssertNil(manager.attemptsLeft())
    }

    func testCheckingPin() throws {
        let secureTime = SecureTimeStub()
        secureTime.tick()
        let manager = try PinManagerImpl(keychain: keychain,
                                         secureTime: secureTime,
                                         configuration: configuration)
        let pin = Pin(value: "1234", option: .fourDigits)
        XCTAssertNoThrow(try manager.save(newPin: pin))

        XCTAssertFalse(manager.check("1111"))
        secureTime.tick()
        XCTAssertFalse(manager.check("2222"))
        secureTime.tick()
        XCTAssertFalse(manager.check("3333"))

        var status = manager.status()
        var wait = configuration.waitTimeByAttempt[3]!
        XCTAssertEqual(status, PinLockDown.timer(wait))
        secureTime.timestamp = 100

        XCTAssertFalse(manager.check("4444"))
        status = manager.status()
        wait = configuration.waitTimeByAttempt[4]!
        XCTAssertEqual(status, PinLockDown.timer(wait))

        secureTime.timestamp = 200
        XCTAssertFalse(manager.check("5555"))
        secureTime.timestamp = 300
        status = manager.status()
        XCTAssertEqual(status, PinLockDown.forever)

        XCTAssertFalse(manager.check("6666"))
    }

    func testIncorrectUsage() throws {
        let secureTime = SecureTimeStub()
        secureTime.tick()
        let manager = try PinManagerImpl(keychain: keychain,
                                         secureTime: secureTime,
                                         configuration: configuration)

        XCTAssertFalse(manager.check("1111"))

        let pin = Pin(value: "1234", option: .fourDigits)
        XCTAssertNoThrow(try manager.save(newPin: pin))

        XCTAssertFalse(manager.check("1111"))

        let pin2 = Pin(value: "4321", option: .fourDigits)
        XCTAssertThrowsError(try manager.save(newPin: pin2))

        XCTAssertThrowsError(try manager.deletePin())
    }
}
