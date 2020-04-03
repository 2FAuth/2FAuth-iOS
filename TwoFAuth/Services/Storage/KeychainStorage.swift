//
//  Copyright © 2015-2017 Authenticator authors
//  Copyright © 2019 2FAuth
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import os.log

class KeychainStorage: Storage {
    var persistentTokens: [PersistentToken]

    let keychain: OTPKeychain
    let userDefaults: UserDefaults

    // Throws an error if the initial state could not be loaded from the keychain.
    init(keychain: OTPKeychain, userDefaults: UserDefaults) throws {
        self.keychain = keychain
        self.userDefaults = userDefaults

        // Try to load persistent tokens.
        let persistentTokenSet = try keychain.allPersistentTokens()
        let sortedIdentifiers = userDefaults.tokenPersistentIdentifiers
        persistentTokens = persistentTokenSet.sorted(withIdentifiersOrder: sortedIdentifiers)

        if persistentTokens.count > sortedIdentifiers.count {
            // If lost tokens were found and appended, save the full list of tokens
            saveTokenOrderLocally()
        }
    }

    func addToken(_ token: Token) throws -> PersistentToken {
        let newPersistentToken = PersistentToken(token: token, id: UUID().uuidString, ckData: nil)
        try keychain.add(newPersistentToken)
        persistentTokens.append(newPersistentToken)
        saveTokenOrderLocally()

        notifyUpdate()

        return newPersistentToken
    }

    func updatePersistentToken(_ persistentToken: PersistentToken) throws {
        try keychain.update(persistentToken)
        // Update the in-memory token, which is still the origin of the table view's data
        persistentTokens = persistentTokens.map {
            if $0.id == persistentToken.id {
                return persistentToken
            }
            return $0
        }

        if persistentTokens.contains(persistentToken) {
            notifyUpdate()
        }
    }

    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) {
        let persistentToken = persistentTokens[origin]
        persistentTokens.remove(at: origin)
        persistentTokens.insert(persistentToken, at: destination)
        saveTokenOrderLocally()

        notifyUpdate()
    }

    func deletePersistentToken(_ persistentToken: PersistentToken) throws {
        try keychain.delete(persistentToken)
        let index = persistentTokens.firstIndex(of: persistentToken)
        if let index = index {
            persistentTokens.remove(at: index)
        }
        saveTokenOrderLocally()

        if index != nil {
            notifyUpdate()
        }
    }
}

// MARK: Internal

extension KeychainStorage {
    func saveTokenOrderLocally() {
        let persistentIdentifiers = persistentTokens.map { $0.id }
        userDefaults.tokenPersistentIdentifiers = persistentIdentifiers
    }

    func notifyUpdate() {
        assert(Thread.isMainThread)

        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: StorageNotification.didUpdate, object: self)
    }
}

// MARK: Order

extension Sequence where Element == PersistentToken {
    func sorted(withIdentifiersOrder identifiers: [String]) -> [PersistentToken] {
        sorted(by: {
            let indexOfA = identifiers.firstIndex(of: $0.id)
            let indexOfB = identifiers.firstIndex(of: $1.id)

            switch (indexOfA, indexOfB) {
            case let (.some(iA), .some(iB)) where iA < iB:
                return true
            default:
                return false
            }
        })
    }
}
