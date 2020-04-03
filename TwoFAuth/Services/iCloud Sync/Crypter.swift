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

import CryptoUtils
import Foundation

enum CrypterError: LocalizedError {
    case encryptionFailure
    case decryptionFailure

    var errorDescription: String? {
        switch self {
        case .encryptionFailure:
            return LocalizedStrings.crypterEncryptionFailure
        case .decryptionFailure:
            return LocalizedStrings.crypterDecryptionFailure
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .encryptionFailure:
            return nil
        case .decryptionFailure:
            return LocalizedStrings.makeSureYouEnterTheCorrectPassphrase
        }
    }
}

protocol Encrypter: AnyObject {
    func encrypt(_ data: Data) throws -> Data
}

protocol Decrypter: AnyObject {
    func decrypt(_ data: Data) throws -> Data
}

typealias Crypter = Decrypter & Encrypter

final class AESCrypter: Crypter {
    let key: Data

    init(key: Data) {
        self.key = key
    }

    convenience init(key: String) {
        self.init(key: key.data)
    }

    func decrypt(_ data: Data) throws -> Data {
        guard let decrypted = AES.decrypt(data, key: key) else {
            throw CrypterError.decryptionFailure
        }
        return decrypted
    }

    func encrypt(_ data: Data) throws -> Data {
        guard let encrypted = AES.encrypt(data, key: key) else {
            throw CrypterError.encryptionFailure
        }
        return encrypted
    }
}
