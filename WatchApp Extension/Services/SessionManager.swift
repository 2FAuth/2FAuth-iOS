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

final class SessionManager: NSObject, WCSessionDelegate {
    private let storage: ReplaceableStorage
    private let userDefaults: UserDefaults

    private let log = OSLog(subsystem: AppDomain, category: String(describing: SessionManager.self))
    private let session = WCSession.default

    private var requestedContext = false

    init(storage: ReplaceableStorage, userDefaults: UserDefaults) {
        self.storage = storage
        self.userDefaults = userDefaults
    }

    func start() {
        session.delegate = self
        session.activate()
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("Session activated %@ (Error: %@)", log: log, type: .debug, activationState.debugDescription, String(describing: error))
        requestAppContext()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        os_log("Session received application context", log: log, type: .debug)

        handle(contextData: applicationContext)
    }

    // MARK: Private

    private func requestAppContext() {
        os_log("Requesting application context", log: log, type: .debug)
        guard session.activationState == .activated else {
            os_log("Requesting application context: failed, session is not activated", log: log, type: .debug)
            return
        }

        session.sendMessage(
            [WatchCommand.context.rawValue: true],
            replyHandler: { responseData in
                self.handle(contextData: responseData)
            },
            errorHandler: { error in
                os_log("Failed to request context: %@", log: self.log, type: .error, String(describing: error))
            }
        )
    }

    private func handle(contextData: [String: Any]) {
        os_log("Processing application context", log: log, type: .debug)

        guard let data = contextData[WatchCommand.context.rawValue] as? Data else {
            os_log("Context data not found", log: log, type: .error)
            return
        }

        let context: AppDataContext
        do {
            context = try JSONDecoder().decode(AppDataContext.self, from: data)
        }
        catch {
            os_log("Decoding context data failed: %@", log: log, type: .error, String(describing: error))
            return
        }

        let persistentTokens = context.persistentTokensData.compactMap(\.persistentToken)
        userDefaults.favIconsByIssuer = context.favIconsByIssuer

        DispatchQueue.main.async {
            self.storage.replace(persistentTokens: persistentTokens)
        }
    }
}
