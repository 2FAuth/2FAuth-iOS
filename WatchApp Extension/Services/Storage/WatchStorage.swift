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

final class WatchStorage: ReplaceableStorage {
    var persistentTokens: [PersistentToken]

    private let keychain: OTPKeychain
    private let userDefaults: UserDefaults

    private let log = OSLog(subsystem: AppDomain, category: String(describing: WatchStorage.self))

    // Throws an error if the initial state could not be loaded from the keychain.
    init(keychain: OTPKeychain, userDefaults: UserDefaults) throws {
        self.keychain = keychain
        self.userDefaults = userDefaults

        // Try to load persistent tokens.
        let persistentTokenSet = try keychain.allPersistentTokens()
        let sortedIdentifiers = userDefaults.tokenPersistentIdentifiers
        persistentTokens = persistentTokenSet.sorted(withIdentifiersOrder: sortedIdentifiers)
    }

    func replace(persistentTokens: [PersistentToken]) {
        os_log("Updating Storage", log: log, type: .debug)

        if self.persistentTokens == persistentTokens {
            os_log("Updating Storage: ignored", log: log, type: .debug)
            return
        }

        do {
            try keychain.deleteAll()
        }
        catch {
            os_log("Failed to delete all keychain items: %@", log: log, type: .error, String(describing: error))
        }

        for persistentToken in persistentTokens {
            do {
                try keychain.add(persistentToken)
            }
            catch {
                os_log("Failed to add persistent token: %@", log: log, type: .error, String(describing: error))
            }
        }

        self.persistentTokens = persistentTokens
        userDefaults.tokenPersistentIdentifiers = persistentTokens.map(\.id)

        notifyUpdate()
    }
}

extension WatchStorage: StorageUpdateNotifiable {}
