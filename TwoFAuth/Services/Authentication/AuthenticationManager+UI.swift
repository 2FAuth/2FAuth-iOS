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

import LocalAuthentication
import UIKit

extension AuthenticationManager {
    var authenticationTitle: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(Self.policy, error: nil)

        let biometryType = context.biometryType
        switch biometryType {
        case .none:
            return LocalizedStrings.passcode
        case .touchID:
            return LocalizedStrings.passcodeAndTouchID
        case .faceID:
            return LocalizedStrings.passcodeAndFaceID
        case .opticID:
            return LocalizedStrings.passcodeAndOpticID
        @unknown default:
            return LocalizedStrings.passcode
        }
    }

    var biometricsOptionTitle: String? {
        let context = LAContext()
        _ = context.canEvaluatePolicy(Self.policy, error: nil)
        let biometryType = context.biometryType

        switch biometryType {
        case .none:
            return nil
        case .touchID:
            return LocalizedStrings.unlockWithTouchID
        case .faceID:
            return LocalizedStrings.unlockWithFaceID
        case .opticID:
            return LocalizedStrings.unlockWithOpticID
        @unknown default:
            return nil
        }
    }

    var biometricsIcon: UIImage? {
        let context = LAContext()
        _ = context.canEvaluatePolicy(Self.policy, error: nil)
        let biometryType = context.biometryType

        switch biometryType {
        case .none:
            return nil
        case .touchID:
            return Styles.Images.touchIDIcon
        case .faceID:
            return Styles.Images.faceIDIcon
        case .opticID:
            return Styles.Images.opticIDIcon
        @unknown default:
            return nil
        }
    }
}
