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

import CommonCrypto
import Foundation

public struct AES {
    public static func encrypt(_ data: Data, key: Data) -> Data? {
        guard let ivData = randomIv() else {
            return nil
        }
        guard let encrypted = perform(UInt32(kCCEncrypt), data: data, key: key, ivData: ivData) else {
            return nil
        }
        var combined = Data()
        combined.append(ivData)
        combined.append(encrypted)
        return combined
    }

    public static func decrypt(_ data: Data, key: Data) -> Data? {
        let ivData = data.subdata(in: 0 ..< kCCBlockSizeAES128)
        let dataRange = data.subdata(in: kCCBlockSizeAES128 ..< data.count)
        return perform(UInt32(kCCDecrypt), data: dataRange, key: key, ivData: ivData)
    }

    private static func perform(_ operation: CCOperation, data: Data, key: Data, ivData: Data) -> Data? {
        guard let dataOut = NSMutableData(length: data.count + kCCBlockSizeAES128) else { return nil }

        let keySize = kCCKeySizeAES128
        let keyRange = 0 ..< keySize
        let keyHash = Hash.SHA384(key)
        let hashKeyData = keyHash.subdata(in: keyRange)
        var dataOutMovedLength: size_t = 0

        let status = CCCrypt(
            operation,
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            (hashKeyData as NSData).bytes,
            keySize,
            (ivData as NSData).bytes,
            (data as NSData).bytes,
            size_t(data.count),
            dataOut.mutableBytes,
            size_t(dataOut.length),
            &dataOutMovedLength
        )

        guard status == kCCSuccess else { return nil }

        dataOut.length = dataOutMovedLength

        return dataOut as Data
    }

    private static func randomIv() -> Data? {
        var bytes = [UInt8](repeating: 0, count: kCCBlockSizeAES128)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            return nil
        }

        return Data(bytes)
    }
}
