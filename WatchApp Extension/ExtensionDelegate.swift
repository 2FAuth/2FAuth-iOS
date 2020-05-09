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

import WatchKit

final class ExtensionDelegate: NSObject, WKExtensionDelegate {
    private let services: Services = WatchServices()
    private lazy var model: WatchModel = { WatchModel(storage: services.storage) }()

    func applicationDidBecomeActive() {
        guard let rootController = WKExtension.shared().rootInterfaceController as? InterfaceController else {
            fatalError("Invalid root controller")
        }

        rootController.model = model
        rootController.favIconFetcher = services.favIconFethcer
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            if #available(watchOSApplicationExtension 5.0, *) {
                switch task {
                case let backgroundTask as WKApplicationRefreshBackgroundTask:
                    // Be sure to complete the background task once you’re done.
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                    // Snapshot tasks have a unique completion call, make sure to set your expiration date
                    snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
                case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                    // Be sure to complete the connectivity task once you’re done.
                    connectivityTask.setTaskCompletedWithSnapshot(false)
                case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                    // Be sure to complete the URL session task once you’re done.
                    urlSessionTask.setTaskCompletedWithSnapshot(false)
                case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                    // Be sure to complete the relevant-shortcut task once you're done.
                    relevantShortcutTask.setTaskCompletedWithSnapshot(false)
                case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                    // Be sure to complete the intent-did-run task once you're done.
                    intentDidRunTask.setTaskCompletedWithSnapshot(false)
                default:
                    // make sure to complete unhandled task types
                    task.setTaskCompletedWithSnapshot(false)
                }
            }
            else {
                // Fallback on earlier versions
            }
        }
    }
}
