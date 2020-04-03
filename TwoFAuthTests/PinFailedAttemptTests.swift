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

class PinFailedAttemptTests: XCTestCase {
    func testBasic() {
        let fa0 = PinFailedAttempt.initial()
        XCTAssert(fa0.failCount == 0)
        XCTAssert(fa0.timestamp == Double.infinity)

        let fa1 = PinFailedAttempt(failCount: 1, timestamp: nil)
        XCTAssert(fa1.failCount == 1)
        XCTAssertNil(fa1.timestamp)

        let fa2 = fa1.next(timestamp: nil)
        XCTAssert(fa2.failCount == fa1.failCount + 1)
        XCTAssertNil(fa2.timestamp)

        let fa3 = fa2.update(timestamp: 10)
        XCTAssert(fa3.failCount == fa2.failCount)
        XCTAssert(fa3.timestamp == 10)

        let fa4 = fa3.next(timestamp: 20)
        XCTAssert(fa4.failCount == fa3.failCount + 1)
        XCTAssert(fa4.timestamp == 20)
    }
}
