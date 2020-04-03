import CloudKit
import Foundation
import os.log

extension CloudSync {
    private enum Keys {
        static let createdCustomZoneKey = "CloudSync.CreatedCustomZone"
        static let createdSubscriptionKey = "CloudSync.CreatedSubscription"
        static let previousDatabaseChangeTokenKey = "CloudSync.PreviousDatabaseChangeToken"
        static let previousZoneChangeTokenKey = "CloudSync.PreviousZoneChangeToken"
    }

    var isCustomZoneCreated: Bool {
        get { defaults.bool(forKey: Keys.createdCustomZoneKey) }
        set { defaults.set(newValue, forKey: Keys.createdCustomZoneKey) }
    }

    var isSubscriptionCreated: Bool {
        get { defaults.bool(forKey: Keys.createdSubscriptionKey) }
        set { defaults.set(newValue, forKey: Keys.createdSubscriptionKey) }
    }

    var previousDatabaseChangeToken: CKServerChangeToken? {
        get {
            guard let tokenData = defaults.object(forKey: Keys.previousDatabaseChangeTokenKey) as? Data else {
                return nil
            }

            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
            }
            catch {
                os_log("Failed to decode CKServerChangeToken for key previousDatabaseChangeToken",
                       log: log, type: .error)
                return nil
            }
        }
        set {
            let key = Keys.previousDatabaseChangeTokenKey

            guard let newValue = newValue else {
                defaults.removeObject(forKey: key)
                return
            }

            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
                defaults.set(data, forKey: key)
            }
            catch {
                defaults.removeObject(forKey: key)
                os_log("Failed to encode change token: %{public}@ for key previousDatabaseChangeToken",
                       log: log, type: .error, String(describing: error))
            }
        }
    }

    var previousZoneChangeToken: CKServerChangeToken? {
        get {
            guard let tokenData = defaults.object(forKey: Keys.previousZoneChangeTokenKey) as? Data else {
                return nil
            }

            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
            }
            catch {
                os_log("Failed to decode CKServerChangeToken for key previousZoneChangeToken",
                       log: log, type: .error)
                return nil
            }
        }
        set {
            let key = Keys.previousZoneChangeTokenKey

            guard let newValue = newValue else {
                defaults.removeObject(forKey: key)
                return
            }

            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
                defaults.set(data, forKey: key)
            }
            catch {
                defaults.removeObject(forKey: key)
                os_log("Failed to encode change token: %{public}@ for key previousZoneChangeToken",
                       log: log, type: .error, String(describing: error))
            }
        }
    }

    func resetState() {
        isCustomZoneCreated = false
        isSubscriptionCreated = false
        previousDatabaseChangeToken = nil
        previousZoneChangeToken = nil
    }
}
