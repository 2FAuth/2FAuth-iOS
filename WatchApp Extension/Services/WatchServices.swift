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

protocol Services: AnyObject {
    var userDefaults: UserDefaults { get }
    var storage: ReplaceableStorage { get }
    var favIconFethcer: WatchFavIconFetcher { get }
}

final class WatchServices: Services {
    let userDefaults: UserDefaults
    let storage: ReplaceableStorage
    let favIconFethcer: WatchFavIconFetcher

    private let sessionManager: SessionManager

    init() {
        userDefaults = UserDefaults.standard
        storage = Self.createWatchStorage(userDefaults: userDefaults)
        favIconFethcer = WatchFavIconFetcher(userDefaults: userDefaults)

        sessionManager = SessionManager(storage: storage, userDefaults: userDefaults)
        sessionManager.start()
    }
}

private extension WatchServices {
    static func createWatchStorage(userDefaults: UserDefaults) -> ReplaceableStorage {
        do {
            let keychain = OTPKeychain()
            return try WatchStorage(keychain: keychain, userDefaults: userDefaults)
        }
        catch {
            preconditionFailure("Failed to initialize Storage: \(error)")
        }
    }
}
