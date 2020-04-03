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

import UIKit

enum Styles {
    enum Colors {
        static let background = UIColor(named: "BackgroundColor")!
        static let secondaryBackground = UIColor.groupTableViewBackground
        static let tertiaryBackground = UIColor(named: "TertiaryBackground")!
        static let segmentedControlBackground = UIColor(named: "SegmentedControlBackgroundColor")!
        static let selectedSegmentTint = UIColor(named: "SelectedSegmentTintColor")!
        static let label = UIColor(named: "LabelColor")!
        static let secondaryLabel = UIColor(named: "SecondaryLabelColor")!
        static let lightText = UIColor(named: "LightTextColor")!
        static let tint = UIColor(named: "TintColor")!
        static let secondaryTint = UIColor(named: "SecondaryTintColor")!
        static let shadow = UIColor(named: "ShadowColor")!
        static let red = UIColor(named: "RedColor")!
        static let divider = UIColor(named: "DividerColor")!
        static let otpCode = UIColor(named: "OTPCodeColor")!
    }

    enum Fonts {
        static let navigationTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)

        static func otpCode() -> UIFont {
            let font = avenirMedium32
            let fontMetrics = UIFontMetrics(forTextStyle: .title1)
            return fontMetrics.scaledFont(for: font)
        }

        /// Font considered title1 with a default content size category
        private static let avenirMedium32 = UIFont(name: "Avenir-Medium", size: 32)!
    }

    enum Sizes {
        static let smallPadding: CGFloat = 4
        static let mediumPadding: CGFloat = 8
        static let largePadding: CGFloat = 16
        static let xLargePadding: CGFloat = 24
        static let iconSize = CGSize(width: 24, height: 24)
        static let cornerRadius: CGFloat = 10
        static let largeCornerRadius: CGFloat = 38
        static let buttonMinSize: CGFloat = 44
        static let progressLineWidth: CGFloat = 2.5
        static let progressSize: CGFloat = 19
        static let uiElementMaxHeight: CGFloat = 1000
    }

    enum Animations {
        static let defaultDuration: TimeInterval = 0.3
        static let progressColorAnimationDuration: TimeInterval = 0.5
    }

    enum Images {
        static let refreshIcon = UIImage(named: "icon-refresh")!
        static let issuerPlaceholder = UIImage(named: "issuer-placeholder")!
        static let settingsIcon = UIImage(named: "icon-settings")!
        static let faceIDIcon = UIImage(named: "icon-face-id")!
        static let touchIDIcon = UIImage(named: "icon-touch-id")!
        static let lockIcon = UIImage(named: "icon-lock")!
        static let cloudNoAccount = UIImage(named: "icon-cloud-no-account")!
        static let cloud = UIImage(named: "icon-cloud")!
        static let lockShield = UIImage(named: "icon-lock-shield")!
    }

    enum Misc {
        static let lockBlurStyle = UIBlurEffect.Style.dark
    }
}
