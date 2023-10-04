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

protocol DataConvertible {
    var data: Data { get }

    init?(data: Data)
}

extension DataConvertible {
    var data: Data {
        withUnsafeBytes(of: self) { Data($0) }
    }

    init?(data: Data) {
        let size = MemoryLayout<Self>.size
        if data.count < size {
            let emptyBytes: [UInt8] = Array(repeating: 0, count: size - data.count)
            let modifiedData = data + emptyBytes
            self = modifiedData.withUnsafeBytes { $0.load(as: Self.self) }
        }
        else if data.count == size {
            self = data.withUnsafeBytes { $0.load(as: Self.self) }
        }
        else {
            return nil
        }
    }
}

extension Float: DataConvertible {}
extension Double: DataConvertible {}
extension Int: DataConvertible {}
extension Int8: DataConvertible {}
extension Int16: DataConvertible {}
extension Int32: DataConvertible {}
extension Int64: DataConvertible {}
extension UInt: DataConvertible {}
extension UInt8: DataConvertible {}
extension UInt16: DataConvertible {}
extension UInt32: DataConvertible {}
extension UInt64: DataConvertible {}

extension String: DataConvertible {
    var data: Data {
        Data(utf8)
    }

    init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }
}

extension URL: DataConvertible {
    var data: Data {
        absoluteString.data
    }

    init?(data: Data) {
        guard let string = String(data: data) else {
            return nil
        }
        self.init(string: string)
    }
}
