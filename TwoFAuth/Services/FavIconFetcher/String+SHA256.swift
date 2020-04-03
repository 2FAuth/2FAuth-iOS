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
#if canImport(CryptoKit)
    import CryptoKit
#endif /* canImport(CryptoKit) */

extension String {
    var sha256: String {
        #if canImport(CryptoKit)
            if #available(iOS 13.0, macOS 10.15, watchOS 6.0, *) {
                return cryptoKit_sha256
            }
            else {
                return commonCrypto_sha256
            }
        #else
            return commonCrypto_sha256
        #endif /* canImport(CryptoKit) */
    }

    private var commonCrypto_sha256: String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return hexString(digest.makeIterator())
    }

    #if canImport(CryptoKit)
        @available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
        private var cryptoKit_sha256: String {
            let data = Data(utf8)
            return hexString(SHA256.hash(data: data).makeIterator())
        }
    #endif /* canImport(CryptoKit) */
}

private func hexString(_ iterator: Array<UInt8>.Iterator) -> String {
    return iterator.map { String(format: "%02x", $0) }.joined()
}
