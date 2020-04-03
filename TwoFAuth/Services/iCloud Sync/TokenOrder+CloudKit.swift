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
import Foundation

extension TokenOrder {
    enum CloudKitDeserializationError: LocalizedError {
        case missingPersistentIdentifiers

        var errorDescription: String? {
            return LocalizedStrings.cannotDecodeDataFromCloud
        }

        var failureReason: String? {
            switch self {
            case .missingPersistentIdentifiers:
                return LocalizedStrings.missingRequiredKeyPersistentIdentifiers
            }
        }
    }

    // CKRecord record name is hardcoded because there is only one CKRecord of this type in the system
    static var recordName: String { "TokenOrderID" }
    static var cloudKitRecordType: String { "TokenOrder" }

    init(record: CKRecord) throws {
        guard let persistentIdentifiers = record[.persistentIdentifiers] as? [String] else {
            throw CloudKitDeserializationError.missingPersistentIdentifiers
        }

        self.init(persistentIdentifiers: persistentIdentifiers)
    }

    func recordIDIn(_ zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: Self.recordName, zoneID: zoneID)
    }

    func recordIn(_ zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = recordIDIn(zoneID)
        let record = CKRecord(recordType: Self.cloudKitRecordType, recordID: recordID)
        record[.persistentIdentifiers] = persistentIdentifiers
        return record
    }
}

private extension CKRecord {
    enum TokenOrderKeys: String {
        case persistentIdentifiers
    }

    subscript(key: TokenOrderKeys) -> Any? {
        get { self[key.rawValue] }
        set { self[key.rawValue] = newValue as? CKRecordValue }
    }
}
