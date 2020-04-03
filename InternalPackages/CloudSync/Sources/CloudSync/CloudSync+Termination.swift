import CloudKit
import Foundation
import os.log

extension CloudSync {
    func deleteZone(completion: @escaping (Error?) -> Void) {
        os_log("Deleting CloudKit zone %@", log: log, type: .info, zoneID.zoneName)

        // Since we're removing all the data, stop any operations
        operationQueue.cancelAllOperations()

        let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [zoneID])

        operation.modifyRecordZonesCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to delete custom CloudKit zone: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                let retrying = error.retryCloudKitOperationIfPossible(self.log) {
                    self.deleteZone(completion: completion)
                }
                if !retrying {
                    // don't handle error globally here, because it's always user-initiated action
                    // and error will be handled in completion block
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
            else {
                os_log("Zone deleted successfully", log: self.log, type: .info)
                self.isCustomZoneCreated = false

                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = database

        operationQueue.addOperation(operation)
    }
}
