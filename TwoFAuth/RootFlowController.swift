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

class RootFlowController: UIViewController {
    let authManager: AuthenticationManager

    weak var lockController: LockScreenViewController?

    private let mainController: UIViewController

    private var didEnterBackground = false

    private lazy var rootNavigationController = {
        UINavigationController(rootViewController: mainController)
    }()

    init(authManager: AuthenticationManager, mainController: UIViewController) {
        self.authManager = authManager
        self.mainController = mainController

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showInitialLockScreen() {
        if authManager.passcode.hasPin {
            let lockController = LockScreenViewController(manager: authManager)
            lockController.delegate = self
            embedChild(lockController)
            self.lockController = lockController
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// Called on `UIApplication.didBecomeActiveNotification` if the pin is set and locking is needed
    func showSubsequentLockScreen() {
        preconditionFailure("To be overridden")
    }

    func hideLockScreen(controller: UIViewController) {
        preconditionFailure("To be overridden")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChild(rootNavigationController)

        // Initially we show the lock screen as a child above the root navigation, because during
        // intialization of the root window creating a new window and making it key and visible
        // will lead to issues with a keyboard.
        showInitialLockScreen()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(didEnterBackgroundNotification),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(didBecomeActiveNotification),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
    }

    override var childForStatusBarStyle: UIViewController? {
        lockController ?? rootNavigationController
    }

    // MARK: Notifications

    @objc
    private func didEnterBackgroundNotification() {
        didEnterBackground = true
    }

    @objc
    private func didBecomeActiveNotification() {
        if authManager.isSettingUpANewPin {
            return
        }

        let passcode = authManager.passcode
        if !passcode.hasPin {
            return
        }

        if !didEnterBackground {
            return
        }
        didEnterBackground = false

        if children.last is LockScreenViewController {
            return
        }

        showSubsequentLockScreen()
    }
}

// MARK: PinControllerDelegate

extension RootFlowController: PinControllerDelegate {
    func pinControllerDidAuthorize(_ controller: PinController) {
        hideLockScreen(controller: controller)
    }
}
