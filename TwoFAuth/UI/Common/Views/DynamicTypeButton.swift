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

final class DynamicTypeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        dynamicTypeButtonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        dynamicTypeButtonSetup()
    }

    // MARK: Private

    private func dynamicTypeButtonSetup() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(setNeedsLayout),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }
}
