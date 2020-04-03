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

enum DeviceType {
    /// Not an iPhone or iPad, i.e. TV
    case unknown

    /// iPhone 5-like (SE, 5S)
    case phoneSmall
    /// iPhone 8-like
    case phoneMedium
    /// iPhone 8 Plus-like
    case phoneLarge
    /// iPhone X-like (11 Pro, Xs)
    case phoneXLarge
    /// iPhone Xs Max / Xʀ (11 Pro Max)
    case phoneXXLarge
    /// Any newly released iPhone
    case phoneAny

    /// iPad 9.7 inch: Pro / Air 2nd / Regular / Mini
    case pad9_7
    /// iPad 10.5 inch: Pro / Air 3rd
    case pad10_5
    /// iPad Pro 11 inch
    case pad11
    /// iPad Pro 12.9 inch
    case pad12_9
    /// Any newly released iPad
    case padAny
}

extension DeviceType {
    static var current: DeviceType {
        if let current = _current {
            return current
        }

        let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        let maxDimension = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        if userInterfaceIdiom == .pad {
            if maxDimension == 1024 {
                _current = .pad9_7
            }
            else if maxDimension == 1112 {
                _current = .pad10_5
            }
            else if maxDimension == 1194 {
                _current = .pad11
            }
            else if maxDimension == 1366 {
                _current = .pad12_9
            }
            else {
                _current = .padAny
            }
        }
        else if userInterfaceIdiom == .phone {
            if maxDimension <= 568 {
                _current = .phoneSmall
            }
            else if maxDimension == 667 {
                _current = .phoneMedium
            }
            else if maxDimension == 736 {
                _current = .phoneLarge
            }
            else if maxDimension == 812 {
                _current = .phoneXLarge
            }
            else if maxDimension == 896 {
                _current = .phoneXXLarge
            }
            else {
                _current = .phoneAny
            }
        }
        else {
            _current = .unknown
        }

        return _current!
    }

    private static var _current: DeviceType?
}

extension DeviceType {
    /// Default left or right padding for specific DeviceType
    var horizontalPadding: CGFloat {
        switch self {
        case .unknown:
            return 16

        case .phoneSmall, .phoneMedium, .phoneXLarge, .phoneAny:
            return 16
        case .phoneLarge, .phoneXXLarge:
            return 20

        case .pad9_7, .pad10_5, .pad11, .pad12_9, .padAny:
            return 20
        }
    }
}
