@testable import CryptoUtils

import XCTest

final class CryptoUtilsTests: XCTestCase {
    let text = "Some text 123 $%^&*()"

    func testHash() {
        let hash = "a79daa69528c09e638d603b1b577984eb54c4afe17ad04644177aee3be1cd72165a7e6f31b63d14cee582d598bf80861"
        let hashData = hash.hex!

        let data = text.data(using: .utf8)!

        let hash1: Data
        if #available(iOS 13.0, macOS 10.15, watchOS 6.0, *) {
            #if canImport(CryptoKit)
                hash1 = Hash.cryptoKitSHA384(data)
            #else
                hash1 = hashData
            #endif /* canImport(CryptoKit) */
        }
        else {
            hash1 = hashData
        }
        let hash2 = Hash.commonCryptoSHA384(data)

        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash2, hashData)
    }

    func testAES() {
        let data = text.data(using: .utf8)!
        let key = "secrect".data(using: .utf8)!

        let encrypted = AES.encrypt(data, key: key)
        XCTAssertNotNil(encrypted)
        let decrypted = AES.decrypt(encrypted!, key: key)
        XCTAssertEqual(decrypted, data)
    }

    static var allTests = [
        ("testHash", testHash),
        ("testAES", testAES),
    ]
}

extension String {
    var hex: Data? {
        var value = self
        var data = Data()

        while !value.isEmpty {
            let subIndex = value.index(value.startIndex, offsetBy: 2)
            let c = String(value[..<subIndex])
            value = String(value[subIndex...])

            var char: UInt8
            if #available(iOS 13.0, *) {
                guard let int = Scanner(string: c).scanInt32(representation: .hexadecimal) else { return nil }
                char = UInt8(int)
            }
            else {
                var int: UInt32 = 0
                Scanner(string: c).scanHexInt32(&int)
                char = UInt8(int)
            }

            data.append(&char, count: 1)
        }

        return data
    }
}
