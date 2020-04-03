import CloudKit
import Foundation
import os.log

extension CloudSync {
    func fetchChanges(completion: ((CloudFetchResult) -> Void)? = nil) {
        os_log("Fetching changes", log: log, type: .debug)

        assert(Thread.isMainThread)

        fetchDatabaseChanges { [weak self] result in
            guard let self = self else { return }

            assert(Thread.isMainThread)

            switch result {
            case .notChanged:
                let fetchedData = CloudFetchedData(changedRecords: [], deletedRecordIDs: [])
                completion?(.success(fetchedData))
            case let .failed(error):
                completion?(.failure(error))
            case .zoneChanged:
                self.fetchZoneChanges(completion: completion)
            case .zoneDeleted:
                let error = CKError(.userDeletedZone)
                self.errorHandler?(error)
                completion?(.failure(error))
            }
        }
    }
}

// MARK: Fetch Database Changes

private extension CloudSync {
    private enum FetchDatabaseChangesResult {
        case notChanged
        case failed(Error)
        case zoneChanged
        case zoneDeleted
    }

    private func fetchDatabaseChanges(completion: @escaping (FetchDatabaseChangesResult) -> Void) {
        os_log("Fetching database changes", log: log, type: .debug)

        assert(Thread.isMainThread)

        var zoneChanged = false
        var zoneDeleted = false

        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: previousDatabaseChangeToken)

        operation.recordZoneWithIDChangedBlock = { [weak self] zoneID in
            if zoneID == self?.zoneID {
                zoneChanged = true
            }
        }

        operation.recordZoneWithIDWasDeletedBlock = { [weak self] zoneID in
            if zoneID == self?.zoneID {
                zoneDeleted = true
            }
        }

        operation.changeTokenUpdatedBlock = { [weak self] token in
            self?.previousDatabaseChangeToken = token
        }

        operation.fetchDatabaseChangesCompletionBlock = { [weak self] token, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to fetch database changes: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                if let error = error as? CKError {
                    if error.code == .changeTokenExpired {
                        os_log("Change token expired, resetting token and trying again",
                               log: self.log, type: .error)

                        self.previousDatabaseChangeToken = nil
                        self.fetchDatabaseChanges(completion: completion)

                        return
                    }

                    let retrying = error.retryCloudKitOperationIfPossible(self.log, idempotent: true) {
                        self.fetchDatabaseChanges(completion: completion)
                    }
                    if retrying {
                        return
                    }
                }

                DispatchQueue.main.async {
                    if let error = error.cloudKitUserActionNeeded {
                        self.errorHandler?(error)
                    }
                    completion(.failed(error))
                }

                return
            }

            os_log("Commiting new database change token", log: self.log, type: .debug)
            self.previousDatabaseChangeToken = token

            let result: FetchDatabaseChangesResult
            if zoneDeleted {
                result = .zoneDeleted
            }
            else if zoneChanged {
                result = .zoneChanged
            }
            else {
                result = .notChanged
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }

        operation.database = database
        operation.qualityOfService = .userInitiated

        operationQueue.addOperation(operation)
    }
}

// MARK: Fetch Zone Changes

private extension CloudSync {
    private func fetchZoneChanges(completion: ((CloudFetchResult) -> Void)?) {
        os_log("Fetching zone changes", log: log, type: .debug)

        assert(Thread.isMainThread)

        var changedRecords = [CKRecord]()
        var deletedRecordIDs = [CKRecord.ID]()
        var retryingZoneError = false

        let operation: CKFetchRecordZoneChangesOperation
        if #available(iOS 12.0, *) {
            let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            options.previousServerChangeToken = previousZoneChangeToken
            let configurations = [zoneID: options]
            operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID],
                                                          configurationsByRecordZoneID: configurations)
        }
        else {
            let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
            options.previousServerChangeToken = previousZoneChangeToken
            let configurations = [zoneID: options]
            operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID],
                                                          optionsByRecordZoneID: configurations)
        }

        operation.recordChangedBlock = { changedRecords.append($0) }

        operation.recordWithIDWasDeletedBlock = { recordID, _ in deletedRecordIDs.append(recordID) }

        operation.recordZoneChangeTokensUpdatedBlock = { [weak self] _, token, _ in
            guard let token = token else { return }

            self?.previousZoneChangeToken = token
        }

        operation.recordZoneFetchCompletionBlock = { [weak self] _, token, _, _, error in
            guard let self = self else { return }

            if let error = error as? CKError {
                os_log("Failed to fetch record zone changes: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                if error.code == .changeTokenExpired {
                    os_log("Zone change token expired, resetting token and trying again",
                           log: self.log, type: .error)

                    self.previousZoneChangeToken = nil
                    retryingZoneError = true

                    DispatchQueue.main.async {
                        self.fetchZoneChanges(completion: completion)
                    }
                }
                else {
                    retryingZoneError = error.retryCloudKitOperationIfPossible(self.log, idempotent: true) {
                        self.fetchZoneChanges(completion: completion)
                    }
                }
            }
            else {
                os_log("Commiting new zone change token", log: self.log, type: .debug)

                self.previousZoneChangeToken = token
            }
        }

        operation.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
            guard let self = self else { return }

            if retryingZoneError {
                return
            }

            if let error = error {
                os_log("Failed to fetch record zone changes: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                let retrying = error.retryCloudKitOperationIfPossible(self.log, idempotent: true) {
                    self.fetchZoneChanges(completion: completion)
                }
                if !retrying {
                    DispatchQueue.main.async {
                        if let error = error.cloudKitUserActionNeeded {
                            self.errorHandler?(error)
                        }

                        completion?(.failure(error))
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    os_log("Finished record zone changes fetch with %{public}d changed record(s) and %{public}d deleted record(s)",
                           log: self.log, type: .info, changedRecords.count, deletedRecordIDs.count)

                    if !changedRecords.isEmpty {
                        self.didChangeRecords?(changedRecords)
                    }

                    if !deletedRecordIDs.isEmpty {
                        let deletedIdentifiers = deletedRecordIDs.map { $0.recordName }
                        self.didDeleteRecords?(deletedIdentifiers)
                    }

                    let fetchedData = CloudFetchedData(changedRecords: changedRecords,
                                                       deletedRecordIDs: deletedRecordIDs)
                    completion?(.success(fetchedData))
                }
            }
        }

        operation.database = database
        operation.qualityOfService = .userInitiated

        operationQueue.addOperation(operation)
    }
}
