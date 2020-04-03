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

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var services: AppServices?
    private var rootController: AppRootFlowController?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let services: AppServices
        #if SCREENSHOT
            if CommandLine.isDemoMode {
                services = DemoServices()
            }
            else {
                services = AppProductionServices()
            }
        #else
            services = AppProductionServices()
        #endif /* SCREENSHOT */
        let rootController = AppRootFlowController(services: services)

        // Subscribe for silent pushes (CloudKit)
        // (Silent pushes are available without any confirmation from the user)
        application.registerForRemoteNotifications()

        self.services = services
        self.rootController = rootController

        let window = RootWindow(frame: UIScreen.main.bounds, authManager: services.authManager)
        window.backgroundColor = .black
        window.tintColor = Styles.Colors.tint
        window.rootViewController = rootController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let services = services else {
            assert(false, "Services not initialized")
            return
        }

        let userDefaults = services.userDefaults

        if !userDefaults.isCloudBackupEnabled {
            completionHandler(.failed)
            return
        }

        let storage = services.storage
        let success = storage.processSubscriptionNotification(with: userInfo, completion: completionHandler)
        if !success {
            completionHandler(.failed)
        }
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let rootController = rootController else {
            assert(false, "AppFlowController not initialized")
            return false
        }

        return rootController.handle(url: url)
    }
}
