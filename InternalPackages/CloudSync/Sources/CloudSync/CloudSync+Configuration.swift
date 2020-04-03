import CloudKit
import Foundation

public extension CloudSync {
    struct Configuration {
        public var containerIdentifier: String
        public var zoneName: String

        var zoneID: CKRecordZone.ID {
            CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        }

        public init(containerIdentifier: String, zoneName: String) {
            self.containerIdentifier = containerIdentifier
            self.zoneName = zoneName
        }
    }
}
