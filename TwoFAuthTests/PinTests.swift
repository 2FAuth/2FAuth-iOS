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

class PinTests: XCTestCase {
    func testCreation() throws {
        let p2 = Pin(value: "1234", option: .fourDigits)
        XCTAssertEqual(p2.value, "1234")

        let p3 = Pin(value: "123456", option: .sixDigits)
        XCTAssertEqual(p3.value, "123456")
    }

    func testEquality() throws {
        let p1 = Pin(value: "1234", option: .fourDigits)
        let p2 = Pin(value: "1234", option: .fourDigits)
        XCTAssertEqual(p1, p2)

        let p3 = Pin(value: "123456", option: .sixDigits)
        XCTAssertNotEqual(p1, p3)

        let p4 = Pin(value: "4321", option: .fourDigits)
        XCTAssertNotEqual(p1, p4)
        XCTAssertNotEqual(p3, p4)
    }
}
