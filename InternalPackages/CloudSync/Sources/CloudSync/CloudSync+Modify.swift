import CloudKit
import Foundation
import os.log

extension CloudSync {
    func modify(recordsToSave: [CKRecord] = [],
                recordIDsToDelete: [CKRecord.ID] = [],
                completion: ((Error?) -> Void)? = nil) {
        assert(Thread.isMainThread)

        if recordsToSave.isEmpty && recordIDsToDelete.isEmpty {
            completion?(nil)

            return
        }

        os_log("Modify with %{public}d record(s) to save, %{public}d record(s) to delete",
               log: log, type: .debug, recordsToSave.count, recordIDsToDelete.count)

        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave,
                                                 recordIDsToDelete: recordIDsToDelete)

        operation.perRecordCompletionBlock = { [weak self] record, error in
            guard let self = self else { return }

            // We're only interested in conflict errors here
            guard let error = error, error.isCloudKitConflict else { return }

            os_log("CloudKit conflict with record of type %{public}@", log: self.log, type: .error, record.recordType)

            guard let resolvedRecord = error.resolveConflict(self.log, with: recentRecordConflictResolver) else {
                os_log("Resolving conflict with record of type %{public}@ returned a nil record. Giving up.",
                       log: self.log, type: .error, record.recordType)

                return
            }

            os_log("Conflict resolved, will retry upload", log: self.log, type: .info)

            DispatchQueue.main.async {
                self.modify(recordsToSave: [resolvedRecord], completion: completion)
            }
        }

        operation.modifyRecordsCompletionBlock = { [weak self] savedRecords, deletedRecordIDs, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to upload records: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                DispatchQueue.main.async {
                    self.handleModifyError(error,
                                           recordsToSave: recordsToSave,
                                           recordIDsToDelete: recordIDsToDelete,
                                           completion: completion)
                }
            }
            else {
                os_log("Successfully modified %{public}d record(s), deleted %{public}d record(s)",
                       log: self.log, type: .info, recordsToSave.count, recordIDsToDelete.count)

                DispatchQueue.main.async {
                    if let savedRecords = savedRecords, !savedRecords.isEmpty {
                        let bufferSet = Set(self.saveBuffer)
                        let savedSet = Set(savedRecords)
                        self.saveBuffer = Array(bufferSet.subtracting(savedSet))

                        self.didChangeRecords?(savedRecords)
                    }

                    if let deletedRecordIDs = deletedRecordIDs, !deletedRecordIDs.isEmpty {
                        let bufferSet = Set(self.deleteBuffer)
                        let deletedSet = Set(deletedRecordIDs)
                        self.deleteBuffer = Array(bufferSet.subtracting(deletedSet))

                        let deletedIdentifiers = deletedRecordIDs.map { $0.recordName }
                        self.didDeleteRecords?(deletedIdentifiers)
                    }

                    completion?(nil)
                }
            }
        }

        // Modify record happens when user changes the corresponding object
        // that means we don't care much about what's currently stored in CloudKit
        operation.savePolicy = .changedKeys

        operation.database = database
        operation.qualityOfService = .userInitiated

        operationQueue.addOperation(operation)
    }
}

// MARK: Error Handling

private extension CloudSync {
    private func handleModifyError(_ error: Error,
                                   recordsToSave: [CKRecord],
                                   recordIDsToDelete: [CKRecord.ID],
                                   completion: ((Error?) -> Void)?) {
        assert(Thread.isMainThread)

        guard let ckError = error as? CKError else {
            os_log("Error was not a CKError, giving up: %{public}@",
                   log: log, type: .fault, String(describing: error))

            completion?(error)

            return
        }

        if ckError.code == .limitExceeded {
            os_log("CloudKit batch limit exceeded, sending records in chunks", log: log, type: .error)

            let splittedRecordsToSave = recordsToSave.splitInHalf()
            let splittedRecordIDsToDelete = recordIDsToDelete.splitInHalf()

            modify(recordsToSave: splittedRecordsToSave.firstHalf,
                   recordIDsToDelete: splittedRecordIDsToDelete.firstHalf,
                   completion: completion)

            modify(recordsToSave: splittedRecordsToSave.secondHalf,
                   recordIDsToDelete: splittedRecordIDsToDelete.secondHalf,
                   completion: completion)
        }
        else {
            let retrying = error.retryCloudKitOperationIfPossible(log) {
                self.modify(recordsToSave: recordsToSave,
                            recordIDsToDelete: recordIDsToDelete,
                            completion: completion)
            }
            if !retrying {
                os_log("Error is not recoverable: %{public}@",
                       log: log, type: .error, String(describing: error))

                if let error = error.cloudKitUserActionNeeded {
                    errorHandler?(error)
                }

                completion?(error)
            }
        }
    }
}

// MARK: Conflict Resolver

private func recentRecordConflictResolver(clientRecord: CKRecord, serverRecord: CKRecord) -> CKRecord? {
    // Most recent record wins. This might not be the best solution but YOLO.

    guard let clientDate = clientRecord.modificationDate, let serverDate = serverRecord.modificationDate else {
        return clientRecord
    }

    if clientDate > serverDate {
        return clientRecord
    }
    else {
        return serverRecord
    }
}

// MARK: Array Extension

private extension Array {
    /// Splits Array into two halves.
    /// If elements count is odd `secondHalf` will have `count / 2 + 1` elements
    /// - Returns: Tuple with two halves
    func splitInHalf() -> (firstHalf: [Element], secondHalf: [Element]) {
        let midpoint = count / 2
        let firstHalf = self[..<midpoint]
        let secondHalf = self[midpoint...]

        return (Array(firstHalf), Array(secondHalf))
    }
}
