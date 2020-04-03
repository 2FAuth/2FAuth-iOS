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

final class AppRootFlowController: RootFlowController {
    private let services: AppServices
    private let model: AppMainModel

    private lazy var lockWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .clear
        window.windowLevel = .normal
        return window
    }()

    init(services: AppServices) {
        self.services = services

        model = AppMainModel(storage: services.storage)

        let controller = AppMainFlowController(storage: services.storage,
                                               userDefaults: services.userDefaults,
                                               favIconFetcher: services.favIconFetcher,
                                               model: model)

        super.init(authManager: services.authManager, mainController: controller)

        controller.delegate = self
        let settingsButton = UIBarButtonItem(image: Styles.Images.settingsIcon,
                                             style: .done,
                                             target: self,
                                             action: #selector(settingsAction))
        settingsButton.accessibilityIdentifier = "main.settings"
        controller.navigationItem.leftBarButtonItem = settingsButton
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction))
        addButton.accessibilityIdentifier = "main.add"
        controller.navigationItem.rightBarButtonItem = addButton
    }

    override func showSubsequentLockScreen() {
        // already shown
        if lockWindow.rootViewController != nil {
            return
        }

        let lockController = LockScreenViewController(manager: authManager)
        lockController.delegate = self
        lockWindow.rootViewController = lockController
        lockWindow.makeKeyAndVisible()
    }

    override func hideLockScreen(controller: UIViewController) {
        let duration = Styles.Animations.defaultDuration
        if lockWindow.rootViewController != nil {
            UIView.animate(withDuration: duration,
                           animations: {
                               self.lockWindow.alpha = 0
                           },
                           completion: { _ in
                               self.lockWindow.rootViewController = nil
                               self.lockWindow.isHidden = true
                               self.lockWindow.alpha = 1
            })
        }
        else {
            transition(from: controller, in: view, duration: duration)
            lockController = nil
            setNeedsStatusBarAppearanceUpdate()
        }
    }
}

// MARK: Public

extension AppRootFlowController {
    func handle(url: URL) -> Bool {
        guard let token = Token(url: url) else {
            return false
        }

        let message = String(format: LocalizedStrings.addNewOneTimePasswordFormat, token.name)

        let alert = UIAlertController(title: LocalizedStrings.addOneTimePassword, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: LocalizedStrings.cancel, style: .cancel)
        alert.addAction(cancelAction)

        let okAction = UIAlertAction(title: LocalizedStrings.ok, style: .default) { _ in
            self.model.addToken(token)
        }
        alert.addAction(okAction)

        let presentingController = UIApplication.topmostController()
        presentingController?.present(alert, animated: true)

        return true
    }
}

// MARK: Actions

extension AppRootFlowController {
    @objc
    private func addAction() {
        let addOTPController = AddOTPViewController(favIconFetcher: services.favIconFetcher)
        addOTPController.delegate = self
        if ProcessInfo().operatingSystemVersion.majorVersion < 13 {
            if UIDevice.current.userInterfaceIdiom == .pad {
                addOTPController.modalPresentationStyle = .formSheet
            }
            else {
                addOTPController.modalPresentationStyle = .overCurrentContext
            }
            addOTPController.modalPresentationCapturesStatusBarAppearance = true
        }
        present(addOTPController, animated: true)
    }

    @objc
    private func settingsAction() {
        let controller = SettingsFlowController(services: services)
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
}

// MARK: AddOTPViewControllerDelegate

extension AppRootFlowController: AddOTPViewControllerDelegate {
    func addOTPViewControllerDidCancel(_ controller: UIViewController) {
        controller.dismiss(animated: true)
    }

    func addOTPViewController(_ controller: UIViewController, didAddToken token: Token) {
        // add token once controller is hidden in case addToken() produces an error to show
        controller.dismiss(animated: true) {
            self.model.addToken(token)
        }
    }
}

// MARK: AddOneTimePasswordDelegate

extension AppRootFlowController: AddOneTimePasswordDelegate {
    func addOneTimePasswordAction() {
        addAction()
    }
}

// MARK: SettingsFlowControllerDelegate

extension AppRootFlowController: SettingsFlowControllerDelegate {
    func settingsFlowDidFinish(controller: SettingsFlowController) {
        controller.dismiss(animated: true)
    }
}
