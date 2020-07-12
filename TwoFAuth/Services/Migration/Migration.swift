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

struct Migration {
    private init() {}

    static func migrateKeychainStorageOptions(userDefaults: UserDefaults) -> Bool {
        if userDefaults.isMigratedV1 {
            return true
        }

        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: kCFBooleanTrue,
            kSecReturnData as String: kCFBooleanTrue,
        ]

        var result: AnyObject?
        let resultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, $0)
        }

        if resultCode == errSecItemNotFound {
            userDefaults.isMigratedV1 = true

            return true
        }

        guard resultCode == errSecSuccess else {
            os_log("Failed to read keychain items %{public}d", log: .default, type: .fault, resultCode)
            return false
        }
        guard let keychainItems = result as? [NSDictionary] else {
            os_log("Failed to read keychain items - invalid format", log: .default, type: .fault)
            return false
        }

        for item in keychainItems {
            guard let identifier = item[kSecAttrAccount] as? NSString,
                let service = item[kSecAttrService] as? NSString,
                let data = item[kSecValueData] as? NSData,
                let generic = item[kSecAttrGeneric] as? NSData else {
                continue
            }

            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: identifier,
                kSecAttrService as String: service,
            ]

            var attributes = [String: Any]()
            attributes[kSecValueData as String] = data
            attributes[kSecAttrGeneric as String] = generic
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as NSString

            let resultCode = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if resultCode != errSecSuccess {
                os_log("Failed to update keychain item: %{public}d", log: .default, type: .error, resultCode)
            }
        }

        userDefaults.isMigratedV1 = true

        return true
    }
}
