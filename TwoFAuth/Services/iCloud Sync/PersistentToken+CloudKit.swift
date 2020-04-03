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

extension PersistentToken {
    enum CloudKitDeserializationError: LocalizedError {
        case missingURL
        case missingSecret
        case invalidURL
        case invalidToken

        var errorDescription: String? {
            return LocalizedStrings.cannotDecodeDataFromCloud
        }

        var failureReason: String? {
            switch self {
            case .missingURL:
                return LocalizedStrings.missingRequiredKeyURL
            case .missingSecret:
                return LocalizedStrings.missingRequiredKeySecret
            case .invalidURL:
                return LocalizedStrings.urlFieldIsInvalid
            case .invalidToken:
                return LocalizedStrings.oneTimePasswordDataIsInvalid
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .missingURL, .missingSecret:
                return nil
            case .invalidURL, .invalidToken:
                return LocalizedStrings.makeSureYouEnterTheCorrectPassphrase
            }
        }
    }

    static var cloudKitRecordType: String { "Token" }

    init(record: CKRecord, decrypter: Decrypter) throws {
        guard let urlEncrypted = record[.url] as? Data else {
            throw CloudKitDeserializationError.missingURL
        }
        guard let secretEncrypted = record[.secret] as? Data else {
            throw CloudKitDeserializationError.missingSecret
        }

        let urlData = try decrypter.decrypt(urlEncrypted)
        let secret = try decrypter.decrypt(secretEncrypted)

        guard let url = URL(data: urlData) else {
            throw CloudKitDeserializationError.invalidURL
        }
        guard let token = Token(url: url, secret: secret) else {
            throw CloudKitDeserializationError.invalidToken
        }
        let id = record.recordID.recordName
        self.init(token: token, id: id, ckData: record.encodedSystemFields)
    }

    func recordIDIn(_ zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: id, zoneID: zoneID)
    }

    func recordIn(_ zoneID: CKRecordZone.ID, encrypter: Encrypter) throws -> CKRecord {
        let url = try token.toURL()
        let urlEncrypted = try encrypter.encrypt(url.data)
        let secretEncrypted = try encrypter.encrypt(token.generator.secret)

        let recordID = recordIDIn(zoneID)
        let record = CKRecord(recordType: Self.cloudKitRecordType, recordID: recordID)
        record[.url] = urlEncrypted
        record[.secret] = secretEncrypted
        return record
    }
}

private extension CKRecord {
    enum TokenKeys: String {
        case url
        case secret
    }

    subscript(key: TokenKeys) -> Any? {
        get { self[key.rawValue] }
        set { self[key.rawValue] = newValue as? CKRecordValue }
    }
}
