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

import CloudKit
import CloudSync

import os.log
import UIKit

final class AppStorage: KeychainStorage, SyncableStorage {
    private let cloudSync: CloudSync
    private let cloudPassphrase: PinManager
    private let log = OSLog(subsystem: AppDomain, category: String(describing: AppStorage.self))

    init(
        keychain: OTPKeychain,
        userDefaults: UserDefaults,
        cloudSync: CloudSync,
        cloudPassphrase: PinManager
    ) throws {
        self.cloudSync = cloudSync
        self.cloudPassphrase = cloudPassphrase

        try super.init(keychain: keychain, userDefaults: userDefaults)

        // Remove passphrase from keychain if there's no flag in UserDefaults
        // eg., user uninstalled and installed the app again
        if !userDefaults.isCloudBackupEnabled {
            do {
                try cloudPassphrase.deletePin()
            }
            catch {
                os_log("Failed to delete iCloud passhprase %{public}@",
                       log: log, type: .error, String(describing: error))
            }
        }

        // Sanity check (keychain was deleted?)
        if !cloudPassphrase.hasPin {
            userDefaults.isCloudBackupEnabled = false
        }

        if userDefaults.isCloudBackupEnabled {
            startSync(userInitiated: false)
        }
    }

    override func addToken(_ token: Token) throws -> PersistentToken {
        let newPersistentToken = try super.addToken(token)

        let sortedIdentifiers = userDefaults.tokenPersistentIdentifiers
        let tokenOrder = TokenOrder(persistentIdentifiers: sortedIdentifiers)

        if userDefaults.isCloudBackupEnabled {
            assert(cloudPassphrase.pin != nil)
            if let key = cloudPassphrase.pin?.value {
                let crypter = AESCrypter(key: key)
                let tokenRecord = try newPersistentToken.recordIn(cloudSync.zoneID, encrypter: crypter)
                let tokenOrderRecord = tokenOrder.recordIn(cloudSync.zoneID)
                cloudSync.save(records: [tokenRecord, tokenOrderRecord])
            }
        }

        return newPersistentToken
    }

    override func updatePersistentToken(_ persistentToken: PersistentToken) throws {
        try super.updatePersistentToken(persistentToken)

        if userDefaults.isCloudBackupEnabled {
            do {
                assert(cloudPassphrase.pin != nil)
                if let key = cloudPassphrase.pin?.value {
                    let crypter = AESCrypter(key: key)
                    let record = try persistentToken.recordIn(cloudSync.zoneID, encrypter: crypter)
                    cloudSync.save(records: [record])
                }
            }
            catch {
                os_log("Failed to encode/decrypt CKRecord from PersistentToken %{public}@",
                       log: log, type: .error, String(describing: error))
            }
        }
    }

    override func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) {
        super.moveTokenFromIndex(origin, toIndex: destination)

        if userDefaults.isCloudBackupEnabled {
            assert(cloudPassphrase.pin != nil)
            if cloudPassphrase.pin?.value != nil {
                let sortedIdentifiers = userDefaults.tokenPersistentIdentifiers
                let tokenOrder = TokenOrder(persistentIdentifiers: sortedIdentifiers)
                let tokenOrderRecord = tokenOrder.recordIn(cloudSync.zoneID)
                cloudSync.save(records: [tokenOrderRecord])
            }
        }
    }

    override func deletePersistentToken(_ persistentToken: PersistentToken) throws {
        try super.deletePersistentToken(persistentToken)

        if userDefaults.isCloudBackupEnabled {
            assert(cloudPassphrase.pin != nil)
            if cloudPassphrase.pin?.value != nil {
                cloudSync.delete(recordIDs: [persistentToken.recordIDIn(cloudSync.zoneID)])

                let sortedIdentifiers = userDefaults.tokenPersistentIdentifiers
                let tokenOrder = TokenOrder(persistentIdentifiers: sortedIdentifiers)
                let tokenOrderRecord = tokenOrder.recordIn(cloudSync.zoneID)
                cloudSync.save(records: [tokenOrderRecord])
            }
        }
    }

    func enableSync() {
        startSync(userInitiated: true)
    }

    func disableSync() {
        cloudSync.disable { error in
            if let error = error, !error.isCloudKitAccountProblem {
                self.notifyFailure(with: error)
            }
            else {
                self.stopSync()
            }
        }
    }

    @discardableResult
    func processSubscriptionNotification(with userInfo: [AnyHashable: Any],
                                         completion: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        cloudSync.processSubscriptionNotification(with: userInfo, completion: completion)
    }
}

// MARK: Private

private extension AppStorage {
    private func startSync(userInitiated: Bool) {
        assert(cloudPassphrase.pin != nil)
        guard let key = cloudPassphrase.pin?.value else {
            return
        }
        let crypter = AESCrypter(key: key)

        userDefaults.isCloudBackupEnabled = true

        // reset previous state
        if userInitiated {
            cloudSync.stop()
        }

        cloudSync.errorHandler = { [weak self] error in
            guard let self = self else { return }

            if error.isCloudKitZoneDeleted || error.isCloudKitAccountProblem {
                self.stopSync()
            }

            self.notifyFailure(with: error)
        }

        cloudSync.didChangeRecords = { [weak self] records in
            self?.processChangedObjects(records, deletetedObjectIDs: [])
        }

        cloudSync.didDeleteRecords = { [weak self] deletedIdentifiers in
            self?.processChangedObjects([], deletetedObjectIDs: deletedIdentifiers)
        }

        // when it's a user initiated action upload all items regardless of previous state
        let notUploaded = userInitiated ? persistentTokens : persistentTokens.filter { $0.ckData == nil }
        let records: [CKRecord] = notUploaded.compactMap { persistentToken in
            do {
                return try persistentToken.recordIn(cloudSync.zoneID, encrypter: crypter)
            }
            catch {
                os_log("Failed to decode/encrypt PersistentToken %{public}@",
                       log: log, type: .error, String(describing: error))
                return nil
            }
        }

        cloudSync.start(currentRecords: records)
    }

    private func stopSync() {
        do {
            try cloudPassphrase.deletePin()
        }
        catch {
            notifyFailure(with: error)
        }

        userDefaults.isCloudBackupEnabled = false

        cloudSync.stop()
        cloudSync.errorHandler = nil
        cloudSync.didChangeRecords = nil
        cloudSync.didDeleteRecords = nil

        persistentTokens = persistentTokens.map {
            var persistentToken = $0
            persistentToken.ckData = nil

            do {
                try keychain.update(persistentToken)
            }
            catch {
                os_log("Failed to update token %{public}@", log: log, type: .error, String(describing: error))
            }

            return persistentToken
        }
    }

    private func processChangedObjects(_ changedObjects: [CKRecord], deletetedObjectIDs: [String]) {
        assert(cloudPassphrase.pin != nil)
        guard let key = cloudPassphrase.pin?.value else {
            return
        }
        let crypter = AESCrypter(key: key)

        var persistentTokensCopy = persistentTokens

        for identifier in deletetedObjectIDs {
            if identifier == TokenOrder.recordName {
                // Corresponding TokenOrder CKRecord was deleted.
                // This is possible only if CloudKit zone was deleted.
                continue
            }

            if let index = persistentTokensCopy.firstIndex(where: { $0.id == identifier }) {
                let persistentToken = persistentTokensCopy.remove(at: index)
                do {
                    try keychain.delete(persistentToken)
                }
                catch {
                    os_log("Failed to delete token %{public}@", log: log, type: .error, String(describing: error))
                }
            }
        }

        var tokenOrderRecord: CKRecord?

        let changedPersistentTokens: [PersistentToken] = changedObjects.compactMap { record in
            if record.recordType == TokenOrder.cloudKitRecordType {
                tokenOrderRecord = record
                return nil
            }

            do {
                return try PersistentToken(record: record, decrypter: crypter)
            }
            catch {
                os_log("Failed to decrypt PersistentToken %{public}@",
                       log: log, type: .error, String(describing: error))
                return nil
            }
        }
        for persistentToken in changedPersistentTokens {
            if let index = persistentTokensCopy.firstIndex(of: persistentToken) {
                do {
                    try keychain.update(persistentToken)
                    persistentTokensCopy[index] = persistentToken
                }
                catch {
                    os_log("Failed to update token %{public}@", log: log, type: .error, String(describing: error))
                }
            }
            else {
                do {
                    try keychain.add(persistentToken)
                    persistentTokensCopy.append(persistentToken)
                }
                catch {
                    os_log("Failed to add token %{public}@", log: log, type: .error, String(describing: error))
                }
            }
        }

        if let tokenOrderRecord = tokenOrderRecord {
            do {
                let tokenOrder = try TokenOrder(record: tokenOrderRecord)
                persistentTokensCopy = persistentTokensCopy.sorted(withIdentifiersOrder: tokenOrder.persistentIdentifiers)
            }
            catch {
                os_log("Failed to init TokenOrder %{public}@", log: log, type: .error, String(describing: error))
            }
        }
        persistentTokens = persistentTokensCopy
        _ = saveTokenOrderLocally()

        notifyUpdate()
    }

    private func notifyFailure(with error: Error) {
        assert(Thread.isMainThread)

        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: SyncableStorageNotification.didFail,
                                object: self,
                                userInfo: [SyncableStorageNotification.errorKey: error])
    }
}
