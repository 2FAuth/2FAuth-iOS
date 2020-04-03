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

extension UITableViewCell {
    /// Device and Preferred Content Size Category specific margins
    /// (same as system's ones - checked on iOS 13.4)
    var deviceSpecificMargins: UIEdgeInsets {
        let vertical = contentSizeCategorySpecificVerticalPadding
        let horizontal = DeviceType.current.horizontalPadding
        return UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    // MARK: Private

    private var contentSizeCategorySpecificVerticalPadding: CGFloat {
        #if APP_EXTENSION
            let category = traitCollection.preferredContentSizeCategory
        #else
            let category = UIApplication.shared.preferredContentSizeCategory
        #endif /* APP_EXTENSION */
        let isPad12_9 = DeviceType.current == .pad12_9
        switch category {
        case .extraSmall, .small:
            return isPad12_9 ? 13 : 9
        case .medium:
            return isPad12_9 ? 14 : 10
        case .large:
            return isPad12_9 ? 15 : 11
        case .extraLarge:
            return isPad12_9 ? 16 : 12
        case .extraExtraLarge:
            return isPad12_9 ? 17 : 13
        case .extraExtraExtraLarge:
            return isPad12_9 ? 18 : 14
        case .accessibilityMedium:
            return isPad12_9 ? 21 : 17
        case .accessibilityLarge:
            return isPad12_9 ? 24 : 20
        case .accessibilityExtraLarge:
            return isPad12_9 ? 28 : 24
        case .accessibilityExtraExtraLarge:
            return isPad12_9 ? 33 : 29
        case .accessibilityExtraExtraExtraLarge:
            return isPad12_9 ? 36 : 32
        default:
            return isPad12_9 ? 15 : 11 // same as Default category (large)
        }
    }
}
