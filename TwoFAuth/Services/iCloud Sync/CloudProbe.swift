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
import CryptoUtils
import Foundation

import os.log

final class CloudProbe {
    private let suiteName: String
    private let cloudSync: CloudSync

    init(configuration: CloudSync.Configuration) {
        suiteName = AppDomain + ".cloudprobe"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("CloudProbe: Failed to initialize UserDefaults")
        }
        cloudSync = CloudSync(defaults: defaults, configuration: configuration)
    }

    func test(passphrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        cloudSync.stop()

        var handled = false

        cloudSync.errorHandler = { [weak self] error in
            guard let self = self else { return }

            if handled {
                return
            }
            handled = true

            self.cloudSync.stop()
            completion(.failure(error))
        }

        cloudSync.didChangeRecords = { _ in }
        cloudSync.didDeleteRecords = { _ in }

        cloudSync.start(currentRecords: []) { [weak self] fetchResult in
            guard let self = self else { return }

            if handled {
                return
            }
            handled = true

            self.cloudSync.stop()

            switch fetchResult {
            case let .success(fetchedData):
                let tokenRecordType = PersistentToken.cloudKitRecordType
                if let record = fetchedData.changedRecords.first(where: { $0.recordType == tokenRecordType }) {
                    do {
                        let crypter = AESCrypter(key: passphrase)
                        _ = try PersistentToken(record: record, decrypter: crypter)

                        completion(.success(()))
                    }
                    catch {
                        completion(.failure(error))
                    }
                }
                else {
                    completion(.success(()))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    deinit {
        cloudSync.stop()
        UserDefaults.standard.removeSuite(named: suiteName)
    }
}
