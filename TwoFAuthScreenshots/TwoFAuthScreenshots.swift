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

import XCTest

class TwoFAuthScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        if let demoScannerPlaceholder = UserDefaults.standard.string(forKey: "demo-scanner-placeholder") {
            app.launchArguments += ["-demo-scanner-placeholder", demoScannerPlaceholder]
        }
        app.launch()
    }

    func testScreenshots() throws {
        let app = XCUIApplication()

        // Show search bar
        app.swipeDown()
        sleep(1)
        snapshot("0-Main")

        app.navigationBars.buttons["main.add"].tap()
        snapshot("1-Scanner")
        app.buttons["scanner.cancel"].tap()

        app.navigationBars.buttons["main.settings"].tap()
        app.cells["settings.manage-otp"].tap()
        snapshot("2-Manager")
        // tap back
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.cells["settings.passcode"].tap()
        snapshot("3-Passcode")
    }
}
