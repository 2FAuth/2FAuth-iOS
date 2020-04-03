import CloudKit
import os.log
import Reachability
import UIKit

extension CloudSync {
    /// Subscribe to Reachability, iCloud account changed and App Will Enter Foreground notifications.
    func startMonitoringNotifications() {
        assert(Thread.isMainThread)

        guard !isMonitoringNotifications else {
            os_log("Skipping %{public}@, already subscribed", log: log, type: .debug, #function)

            return
        }
        isMonitoringNotifications = true

        os_log("Starting notifications monitoring", log: log, type: .debug)

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self,
                                       selector: #selector(reachabilityDidChange(_:)),
                                       name: .reachabilityChanged,
                                       object: reachability)
        do {
            try reachability.startNotifier()
        }
        catch {
            os_log("Could not start reachability notifier: %{public}@",
                   log: log, type: .error, String(describing: error))
        }

        notificationCenter.addObserver(self,
                                       selector: #selector(accountDidChange(_:)),
                                       name: .CKAccountChanged,
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillEnterForeground(_:)),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
    }

    func stopMonitoringNotifications() {
        assert(Thread.isMainThread)

        guard isMonitoringNotifications else {
            os_log("Skipping %{public}@, already unsubscribed", log: log, type: .debug, #function)

            return
        }
        isMonitoringNotifications = false

        os_log("Stopping notifications monitoring", log: log, type: .debug)

        reachability.stopNotifier()

        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }

    // MARK: Private

    @objc
    private func reachabilityDidChange(_ notification: Notification) {
        assert(Thread.isMainThread)

        let connection = reachability.connection
        os_log("Internet connection did change %{public}@", log: log, type: .info, connection.description)
        if connection != .unavailable {
            verifyAndFetch()
        }
    }

    @objc
    private func accountDidChange(_ notification: Notification) {
        assert(!Thread.isMainThread)

        os_log("iCloud account has been changed %{public}@",
               log: log, type: .info, String(describing: notification.userInfo))
        DispatchQueue.main.async {
            self.verifyAndFetch()
        }
    }

    @objc
    private func applicationWillEnterForeground(_ notification: Notification) {
        assert(Thread.isMainThread)

        os_log("Application will enter foreground", log: log, type: .info)
        verifyAndFetch()
    }
}
