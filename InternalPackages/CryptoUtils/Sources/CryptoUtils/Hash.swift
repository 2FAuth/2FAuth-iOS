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

struct Hash {
    static func SHA384(_ data: Data) -> Data {
        #if canImport(CryptoKit)
            if #available(iOS 13.0, macOS 10.15, watchOS 6.0, *) {
                return cryptoKitSHA384(data)
            }
            else {
                return commonCryptoSHA384(data)
            }
        #else
            return commonCryptoSHA384(data)
        #endif /* canImport(CryptoKit) */
    }

    #if canImport(CryptoKit)
        @available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
        static func cryptoKitSHA384(_ data: Data) -> Data {
            let hash = Array(CryptoKit.SHA384.hash(data: data).makeIterator())
            return Data(hash)
        }
    #endif /* canImport(CryptoKit) */

    static func commonCryptoSHA384(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA384(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}
