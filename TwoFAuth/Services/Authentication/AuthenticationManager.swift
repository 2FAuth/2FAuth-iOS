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

final class AuthenticationManager {
    static let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics

    let passcode: PinManager
    var isSettingUpANewPin: Bool = false

    private let userDefaults: UserDefaults

    /// Check if device supports biometrics auth
    var isBiometricsAvailable: Bool {
        let context = LAContext()
        _ = context.canEvaluatePolicy(Self.policy, error: nil)

        let biometryType = context.biometryType
        switch biometryType {
        case .none:
            return false
        case .touchID:
            return true
        case .faceID:
            return true
        case .opticID:
            return true
        @unknown default:
            return false
        }
    }

    /// Check if user enabled biometrics auth
    var isBiometricsEnabled: Bool {
        get { userDefaults.isBiometricsAuthenticationEnabled }
        set { userDefaults.isBiometricsAuthenticationEnabled = newValue }
    }

    /// Check if device supports biometrics, it was enabled by user and passcode wasn't locked down
    var isBiometricsAllowed: Bool {
        isBiometricsAvailable && isBiometricsEnabled && passcode.attemptsLeft() == nil
    }

    init(passcode: PinManager, userDefaults: UserDefaults) {
        self.passcode = passcode
        self.userDefaults = userDefaults
    }

    func authenticateUsingBiometrics(_ completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.evaluatePolicy(Self.policy, localizedReason: LocalizedStrings.biometricsReason) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}

// MARK: Settings

private extension UserDefaults {
    enum Keys {
        static let biometricsAuthenticationEnabledKey = AppDomain + ".biometrics-authentication-enabled"
    }

    var isBiometricsAuthenticationEnabled: Bool {
        get { bool(forKey: Keys.biometricsAuthenticationEnabledKey) }
        set { set(newValue, forKey: Keys.biometricsAuthenticationEnabledKey) }
    }
}
