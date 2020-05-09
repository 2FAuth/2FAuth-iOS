//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Andrew Podkovyrin. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import os.log
import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate {
    private let storage: Storage
    private let userDefaults: UserDefaults
    private let log = OSLog(subsystem: AppDomain, category: String(describing: WatchSessionManager.self))

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private var validSession: WCSession? {
        guard let session = session, session.isPaired && session.isWatchAppInstalled else {
            return nil
        }
        return session
    }

    init(storage: Storage, userDefaults: UserDefaults) {
        self.storage = storage
        self.userDefaults = userDefaults

        super.init()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(updateContext),
                                       name: StorageNotification.didUpdate,
                                       object: nil)
    }

    func start() {
        session?.delegate = self
        session?.activate()
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("Session activation complete: %@ (Error: %@)", log: log, type: .debug, activationState.debugDescription, String(describing: error))

        if activationState == .activated {
            updateContext()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        os_log("Session became inactive", log: log, type: .debug)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        os_log("Session deactivated", log: log, type: .debug)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let application = UIApplication.shared
        var identifier: UIBackgroundTaskIdentifier = .invalid
        identifier = application.beginBackgroundTask {
            if identifier != .invalid {
                UIApplication.shared.endBackgroundTask(identifier)
            }
            identifier = .invalid
        }

        if message[WatchCommand.context.rawValue] != nil {
            let context = appContext()
            replyHandler(context)
        }
        else {
            assert(false, "Unhandled message: \(message)")
        }
    }

    // MARK: Private

    @objc
    private func updateContext() {
        os_log("Updating context...", log: log, type: .debug)

        guard let session = validSession else {
            os_log("Updating context: session is not valid", log: log, type: .debug)
            return
        }

        guard session.activationState == .activated else {
            os_log("Updating context: session is not activated", log: log, type: .debug)
            return
        }

        do {
            let context = appContext()
            try session.updateApplicationContext(context)
        }
        catch {
            os_log("Updating context: failed update application context: %@", log: log, type: .error, String(describing: error))
        }
    }

    private func appContext() -> [String: Any] {
        let persistentTokens = storage.persistentTokens
        let persistentTokensData = persistentTokens.compactMap(PersistentTokenData.init(persistentToken:))
        let context = AppDataContext(persistentTokensData: persistentTokensData,
                                     favIconsByIssuer: userDefaults.favIconsByIssuer)
        do {
            let data = try JSONEncoder().encode(context)
            return [WatchCommand.context.rawValue: data]
        }
        catch {
            os_log("Encoding context failed: %@", log: log, type: .error, String(describing: error))
            return [:]
        }
    }
}
