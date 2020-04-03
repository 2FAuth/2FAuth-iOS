import CloudKit
import Foundation
import os.log

extension CloudSync {
    func verifyAndSync(fetchCompletion: ((CloudFetchResult) -> Void)?) {
        assert(Thread.isMainThread)

        os_log("Verifying account and syncing (modify + fetch)", log: log, type: .info)

        verifyAccountAndPerformIfSuccess { [weak self] in
            guard let self = self else { return }

            self.modify(recordsToSave: self.saveBuffer,
                        recordIDsToDelete: self.deleteBuffer,
                        completion: { [weak self] _ in
                            self?.fetchChanges(completion: fetchCompletion)
            })
        }
    }

    func verifyAndFetch() {
        assert(Thread.isMainThread)

        os_log("Verifying account and fetching", log: log, type: .info)

        verifyAccountAndPerformIfSuccess { [weak self] in
            self?.fetchChanges()
        }
    }
}

// MARK: Verify Account

private extension CloudSync {
    /// Verifies iCloud account status and continues in case of success.
    private func verifyAccountAndPerformIfSuccess(successBlock: @escaping () -> Void) {
        assert(Thread.isMainThread)

        container.accountStatus(log) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.operationQueue.cancelAllOperations()

                DispatchQueue.main.async {
                    self.errorHandler?(error)
                }
            }
            else {
                self.workingQueue.async { [weak self] in
                    guard let self = self else { return }

                    self.createZoneIfNeeded()
                    self.operationQueue.waitUntilAllOperationsAreFinished()
                    guard self.isCustomZoneCreated else { return }

                    self.createSubscriptionIfNeeded()
                    self.operationQueue.waitUntilAllOperationsAreFinished()
                    guard self.isSubscriptionCreated else { return }

                    DispatchQueue.main.async(execute: successBlock)
                }
            }
        }
    }
}

// MARK: Create Custom Zone

private extension CloudSync {
    private func createZoneIfNeeded() {
        guard !isCustomZoneCreated else {
            os_log("Already have custom zone, skipping creation but checking if zone really exists",
                   log: log, type: .debug)

            checkZone()

            return
        }

        os_log("Creating CloudKit zone %@", log: log, type: .info, zoneID.zoneName)

        let zone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)

        operation.modifyRecordZonesCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to create custom CloudKit zone: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                let retrying = error.retryCloudKitOperationIfPossible(self.log) {
                    self.createZoneIfNeeded()
                }
                if !retrying {
                    if let error = error.cloudKitUserActionNeeded {
                        DispatchQueue.main.async {
                            self.errorHandler?(error)
                        }
                    }
                }
            }
            else {
                os_log("Zone created successfully", log: self.log, type: .info)
                self.isCustomZoneCreated = true
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = database

        operationQueue.addOperation(operation)
    }

    private func checkZone() {
        let operation = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])

        operation.fetchRecordZonesCompletionBlock = { [weak self] ids, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to check for custom zone existence: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                let retrying = error.retryCloudKitOperationIfPossible(self.log, idempotent: true) {
                    self.checkZone()
                }
                if !retrying {
                    os_log("Irrecoverable error when fetching custom zone, assuming it doesn't exist: %{public}@",
                           log: self.log, type: .error, String(describing: error))

                    DispatchQueue.main.async {
                        self.isCustomZoneCreated = false

                        if let error = error.cloudKitUserActionNeeded {
                            self.errorHandler?(error)
                        }
                        else {
                            self.createZoneIfNeeded()
                        }
                    }
                }
            }
            else if ids == nil || ids?.isEmpty == true {
                os_log("Custom zone reported as existing, but it doesn't exist. Creating.",
                       log: self.log, type: .error)

                DispatchQueue.main.async {
                    self.isCustomZoneCreated = false
                    self.createZoneIfNeeded()
                }
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = database

        operationQueue.addOperation(operation)
    }
}

// MARK: Create Subscription

private extension CloudSync {
    private func createSubscriptionIfNeeded() {
        guard !isSubscriptionCreated else {
            os_log("Already subscribed to private database changes, skipping subscription but checking if it really exists",
                   log: log, type: .debug)

            checkSubscription()

            return
        }

        let subscription = CKDatabaseSubscription(subscriptionID: Constants.subscriptionID)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription],
                                                       subscriptionIDsToDelete: nil)

        operation.modifySubscriptionsCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to create private CloudKit subscription: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                let retrying = error.retryCloudKitOperationIfPossible(self.log) {
                    self.createSubscriptionIfNeeded()
                }
                if !retrying {
                    if let error = error.cloudKitUserActionNeeded {
                        DispatchQueue.main.async {
                            self.errorHandler?(error)
                        }
                    }
                }
            }
            else {
                os_log("Private subscription created successfully", log: self.log, type: .info)
                self.isSubscriptionCreated = true
            }
        }

        operation.database = database
        operation.qualityOfService = .userInitiated

        operationQueue.addOperation(operation)
    }

    private func checkSubscription() {
        let operation = CKFetchSubscriptionsOperation(subscriptionIDs: [Constants.subscriptionID])

        operation.fetchSubscriptionCompletionBlock = { [weak self] ids, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to check for private zone subscription existence: %{public}@",
                       log: self.log, type: .error, String(describing: error))

                let retrying = error.retryCloudKitOperationIfPossible(self.log, idempotent: true) {
                    self.checkSubscription()
                }
                if !retrying {
                    os_log("Irrecoverable error when fetching private zone subscription, assuming it doesn't exist: %{public}@",
                           log: self.log, type: .error, String(describing: error))

                    DispatchQueue.main.async {
                        if let error = error.cloudKitUserActionNeeded {
                            self.errorHandler?(error)
                        }

                        self.isSubscriptionCreated = false
                        self.createSubscriptionIfNeeded()
                    }
                }
            }
            else if ids == nil || ids?.isEmpty == true {
                os_log("Private subscription reported as existing, but it doesn't exist. Creating.",
                       log: self.log, type: .error)

                DispatchQueue.main.async {
                    self.isSubscriptionCreated = false
                    self.createSubscriptionIfNeeded()
                }
            }
        }

        operation.database = database
        operation.qualityOfService = .userInitiated

        operationQueue.addOperation(operation)
    }
}
