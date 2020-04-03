import CloudKit
import os.log
import Reachability
import UIKit

public struct CloudFetchedData {
    public let changedRecords: [CKRecord]
    public let deletedRecordIDs: [CKRecord.ID]

    public var isEmpty: Bool { changedRecords.isEmpty && deletedRecordIDs.isEmpty }
}

public enum CloudFetchResult {
    case success(CloudFetchedData)
    case failure(Error)
}

public final class CloudSync {
    public let zoneID: CKRecordZone.ID

    /// Called on irrecoverable error.
    public var errorHandler: ((Error) -> Void)?

    /// Called after records were updated with CloudKit data.
    public var didChangeRecords: (([CKRecord]) -> Void)?

    /// Called when records were deleted remotely.
    public var didDeleteRecords: (([String]) -> Void)?

    let log = OSLog(subsystem: "CloudSync", category: String(describing: CloudSync.self))

    let defaults: UserDefaults

    var saveBuffer: [CKRecord] = []
    var deleteBuffer: [CKRecord.ID] = []

    var isMonitoringNotifications = false

    private(set) lazy var workingQueue = {
        DispatchQueue(label: "CloudSync.WorkingQueue", qos: .userInitiated)
    }()

    let container: CKContainer
    var database: CKDatabase { container.privateCloudDatabase }

    private(set) lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        // don't allow simultaneous operations to prevent collisions
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = underlyingQueue
        queue.name = "CloudSync.Queue"
        return queue
    }()

    private lazy var underlyingQueue = {
        DispatchQueue(label: "CloudSync.UnderlyingQueue", qos: .userInitiated)
    }()

    private(set) lazy var reachability: Reachability = {
        // Use CloudKit Web Service URL as host to check internet connection
        guard let reachability = try? Reachability(hostname: Constants.cloudKitHost) else {
            preconditionFailure("Failed to initialized Reachability. Invalid host?")
        }
        return reachability
    }()

    public init(defaults: UserDefaults, configuration: Configuration) {
        zoneID = configuration.zoneID
        self.defaults = defaults
        container = CKContainer(identifier: configuration.containerIdentifier)
    }
}

public extension CloudSync {
    func start(currentRecords: [CKRecord], fetchCompletion: ((CloudFetchResult) -> Void)? = nil) {
        assert(Thread.isMainThread)
        assert(errorHandler != nil && didChangeRecords != nil && didDeleteRecords != nil,
               "Provide CloudSync handlers before starting up")

        saveBuffer = currentRecords

        startMonitoringNotifications()
        verifyAndSync(fetchCompletion: fetchCompletion)
    }

    func stop() {
        assert(Thread.isMainThread)

        stopMonitoringNotifications()
        resetState()
        operationQueue.cancelAllOperations()
        saveBuffer = []
        deleteBuffer = []
    }

    func disable(completion: @escaping (Error?) -> Void) {
        assert(Thread.isMainThread)

        deleteZone(completion: completion)
    }

    func save(records: [CKRecord]) {
        assert(Thread.isMainThread)

        if records.isEmpty {
            return
        }

        saveBuffer.append(contentsOf: records)
        modify(recordsToSave: records)
    }

    func delete(recordIDs: [CKRecord.ID]) {
        assert(Thread.isMainThread)

        if recordIDs.isEmpty {
            return
        }

        deleteBuffer.append(contentsOf: recordIDs)
        modify(recordIDsToDelete: recordIDs)
    }

    @discardableResult
    func processSubscriptionNotification(with userInfo: [AnyHashable: Any],
                                         completion: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            os_log("Not a CKNotification", log: log, type: .error)
            return false
        }

        guard notification.subscriptionID == Constants.subscriptionID else {
            os_log("Unsupported subscription ID", log: log, type: .debug)
            return false
        }

        os_log("Received remote CloudKit notification for user data", log: log, type: .debug)

        fetchChanges { result in
            switch result {
            case let .success(fetchedData):
                completion(fetchedData.isEmpty ? .noData : .newData)
            case .failure:
                completion(.failed)
            }
        }

        return true
    }
}
