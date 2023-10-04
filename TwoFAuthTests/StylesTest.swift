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

class StylesTest: XCTestCase {
    func testColors() {
        let colors = Styles.Colors.self
        XCTAssertNotNil(colors.background)
        XCTAssertNotNil(colors.secondaryBackground)
        XCTAssertNotNil(colors.tertiaryBackground)
        XCTAssertNotNil(colors.segmentedControlBackground)
        XCTAssertNotNil(colors.selectedSegmentTint)
        XCTAssertNotNil(colors.label)
        XCTAssertNotNil(colors.secondaryLabel)
        XCTAssertNotNil(colors.lightText)
        XCTAssertNotNil(colors.tint)
        XCTAssertNotNil(colors.secondaryTint)
        XCTAssertNotNil(colors.shadow)
        XCTAssertNotNil(colors.red)
        XCTAssertNotNil(colors.divider)
        XCTAssertNotNil(colors.otpCode)
    }

    func testFonts() {
        let fonts = Styles.Fonts.self
        XCTAssertNotNil(fonts.otpCode)
    }

    func testImages() {
        let images = Styles.Images.self
        XCTAssertNotNil(images.refreshIcon)
        XCTAssertNotNil(images.issuerPlaceholder)
        XCTAssertNotNil(images.settingsIcon)
        XCTAssertNotNil(images.opticIDIcon)
        XCTAssertNotNil(images.faceIDIcon)
        XCTAssertNotNil(images.touchIDIcon)
        XCTAssertNotNil(images.lockIcon)
        XCTAssertNotNil(images.cloudNoAccount)
        XCTAssertNotNil(images.cloud)
        XCTAssertNotNil(images.lockShield)
    }
}
