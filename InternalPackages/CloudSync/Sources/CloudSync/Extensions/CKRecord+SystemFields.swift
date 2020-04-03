import CloudKit

public extension CKRecord {
    var encodedSystemFields: Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        encodeSystemFields(with: coder)
        coder.finishEncoding()

        return coder.encodedData
    }
}
