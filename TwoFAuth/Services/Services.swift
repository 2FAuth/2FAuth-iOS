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

import Foundation

import os.log

protocol Services: AnyObject {
    var userDefaults: UserDefaults { get }
    var favIconFetcher: FavIconFetcher { get }
    var storage: Storage { get }
    var authManager: AuthenticationManager { get }
}

class ProductionServices: Services {
    let userDefaults: UserDefaults
    let favIconFetcher: FavIconFetcher
    let storage: Storage
    let authManager: AuthenticationManager

    init() {
        userDefaults = UserDefaults.appGroupDefaults()
        favIconFetcher = FavIconFetcher(userDefaults: userDefaults)
        storage = Self.createKeychainStorage(userDefaults: userDefaults)
        authManager = Self.createAuthenticationManager(userDefaults: userDefaults)
    }
}

extension Services {
    static func createKeychainStorage(userDefaults: UserDefaults) -> KeychainStorage {
        let keychain = OTPKeychain()
        do {
            return try KeychainStorage(keychain: keychain, userDefaults: userDefaults)
        }
        catch {
            preconditionFailure("Failed to initialize KeychainStorage: \(error)")
        }
    }

    static func createAuthenticationManager(userDefaults: UserDefaults) -> AuthenticationManager {
        do {
            #if DEBUG
                let configuration = PinAttemptsConfiguration.passcodeDebug()
            #else
                let configuration = PinAttemptsConfiguration.passcodeProduction()
            #endif /* DEBUG */

            let passcodeKeychain = PinKeychain(domain: "passcode")
            let passcode = try PinManagerImpl(keychain: passcodeKeychain,
                                              secureTime: SecureTimeClock.shared,
                                              configuration: configuration)
            return AuthenticationManager(passcode: passcode, userDefaults: userDefaults)
        }
        catch {
            preconditionFailure("Failed to initialize Passcode PinManager: \(error)")
        }
    }
}
