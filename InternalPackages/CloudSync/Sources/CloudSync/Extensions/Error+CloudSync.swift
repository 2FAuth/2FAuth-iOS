import CloudKit
import Foundation
import os.log

public extension Error {
    /// Whether this error represents a "zone not found" or a "user deleted zone" error
    var isCloudKitZoneDeleted: Bool {
        guard let ckError = self as? CKError else { return false }

        return [.zoneNotFound, .userDeletedZone].contains(ckError.code)
    }

    /// Whether this error represents any CloudKit account related problem
    var isCloudKitAccountProblem: Bool {
        guard let ckError = self as? CKError else { return false }

        return [.internalError, .notAuthenticated, .managedAccountRestricted].contains(ckError.code)
    }
}

// MARK: Internal

extension Error {
    /// Whether this error is a CloudKit server record changed error, representing a record conflict
    var isCloudKitConflict: Bool {
        guard let ckError = self as? CKError else { return false }

        return ckError.code == .serverRecordChanged
    }

    /// Returns CKError if the zone was deleted or there is CloudKit account problem
    var cloudKitUserActionNeeded: CKError? {
        cloudKitAccountProblem ?? cloudKitZoneDeleted
    }

    /// Returns CKError if it represents a "zone not found" or a "user deleted zone" error
    private var cloudKitZoneDeleted: CKError? {
        findCKError { $0.isCloudKitZoneDeleted }
    }

    /// Returns CKError if it represents any CloudKit account related problem
    private var cloudKitAccountProblem: CKError? {
        findCKError { $0.isCloudKitAccountProblem }
    }

    /// Uses the `resolver` closure to resolve a conflict, returning the conflict-free record
    ///
    /// - Parameter resolver: A closure that will receive the client record as the first param and the server record as the second param.
    /// This closure is responsible for handling the conflict and returning the conflict-free record.
    /// - Returns: The conflict-free record returned by `resolver`
    func resolveConflict(_ log: OSLog, with resolver: (CKRecord, CKRecord) -> CKRecord?) -> CKRecord? {
        guard let ckError = self as? CKError else {
            os_log("resolveConflict called on an error that was not a CKError. The error was %{public}@",
                   log: log, type: .fault, String(describing: self))
            return nil
        }

        guard ckError.code == .serverRecordChanged else {
            os_log("resolveConflict called on a CKError that was not a serverRecordChanged error. The error was %{public}@",
                   log: log, type: .fault, String(describing: ckError))
            return nil
        }

        guard let clientRecord = ckError.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord else {
            os_log("Failed to obtain client record from serverRecordChanged error. The error was %{public}@",
                   log: log, type: .fault, String(describing: ckError))
            return nil
        }

        guard let serverRecord = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord else {
            os_log("Failed to obtain server record from serverRecordChanged error. The error was %{public}@",
                   log: log, type: .fault, String(describing: ckError))
            return nil
        }

        return resolver(clientRecord, serverRecord)
    }

    /// Retries a CloudKit operation if the error suggests it
    ///
    /// - Parameters:
    ///   - log: The logger to use for logging information about the error handling, uses the default one if not set
    ///   - block: The block that will execute the operation later if it can be retried
    /// - Returns: Whether or not it was possible to retry the operation
    func retryCloudKitOperationIfPossible(_ log: OSLog,
                                          idempotent: Bool = false,
                                          with block: @escaping () -> Void) -> Bool {
        guard let ckError = self as? CKError else { return false }

        if let retryAfter = ckError.retryAfterSeconds {
            os_log("Error is recoverable. Will retry after %{public}f seconds", log: log, type: .error, retryAfter)
            DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter, execute: block)

            return true
        }
        else if idempotent && ckError.code == .serverResponseLost {
            // The server received and processed this request, but the response was lost due to a network failure.
            // There is no guarantee that this request succeeded.
            // Your client should re-issue the request (if it is idempotent)

            os_log("Error is recoverable (response was lost). Will retry now", log: log, type: .error)
            DispatchQueue.main.async(execute: block)

            return true
        }

        return false
    }

    private func findCKError(condition: (CKError) -> Bool) -> CKError? {
        guard let ckError = self as? CKError else { return nil }

        if condition(ckError) {
            return ckError
        }

        if let partialErrors = ckError.partialErrorsByItemID {
            for error in partialErrors.values {
                if let innerError = error as? CKError, condition(innerError) {
                    return innerError
                }
            }
        }

        return nil
    }
}
