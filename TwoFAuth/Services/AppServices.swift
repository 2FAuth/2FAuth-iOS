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

import CloudSync
import Foundation

protocol AppServices: AnyObject {
    var userDefaults: UserDefaults { get }
    var favIconFetcher: FavIconFetcher { get }
    var storage: SyncableStorage { get }
    var authManager: AuthenticationManager { get }
    var cloudConfig: CloudSync.Configuration { get }
    var cloudPassphrase: PinManager { get }
}

class AppProductionServices: AppServices {
    let userDefaults: UserDefaults
    let favIconFetcher: FavIconFetcher
    let storage: SyncableStorage
    let authManager: AuthenticationManager
    let cloudConfig: CloudSync.Configuration
    let cloudPassphrase: PinManager

    private let watchManager: WatchSessionManager

    init() {
        userDefaults = UserDefaults.appGroupDefaults()
        favIconFetcher = FavIconFetcher(userDefaults: userDefaults)
        cloudConfig = Self.createCloudSyncConfiguration()
        cloudPassphrase = Self.createCloudPassphrase()
        storage = Self.createAppStorage(userDefaults: userDefaults,
                                        cloudConfig: cloudConfig,
                                        cloudPassphrase: cloudPassphrase)
        authManager = ProductionServices.createAuthenticationManager(userDefaults: userDefaults)

        watchManager = WatchSessionManager(storage: storage, userDefaults: userDefaults)
        watchManager.start()
    }
}

extension AppServices {
    static func createCloudSyncConfiguration() -> CloudSync.Configuration {
        CloudSync.Configuration(containerIdentifier: "iCloud.app.2fauth", zoneName: "PersistentTokensZone")
    }

    static func createCloudPassphrase() -> PinManager {
        do {
            #if DEBUG
                let cloudConfiguration = PinAttemptsConfiguration.cloudDebug()
            #else
                let cloudConfiguration = PinAttemptsConfiguration.cloudProduction()
            #endif /* DEBUG */

            let cloudKeychain = PinKeychain(domain: "cloud")
            return try PinManagerImpl(keychain: cloudKeychain,
                                      secureTime: SecureTimeClock.shared,
                                      configuration: cloudConfiguration)
        }
        catch {
            preconditionFailure("Failed to initialize Cloud PinManager: \(error)")
        }
    }

    static func createAppStorage(userDefaults: UserDefaults,
                                 cloudConfig: CloudSync.Configuration,
                                 cloudPassphrase: PinManager) -> AppStorage {
        do {
            let keychain = OTPKeychain()
            let cloudSync = CloudSync(defaults: userDefaults, configuration: cloudConfig)

            return try AppStorage(keychain: keychain,
                                  userDefaults: userDefaults,
                                  cloudSync: cloudSync,
                                  cloudPassphrase: cloudPassphrase)
        }
        catch {
            preconditionFailure("Failed to initialize Storage: \(error)")
        }
    }
}
