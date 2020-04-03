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

final class PasscodeSettingsFlowController: UIViewController {
    private let manager: AuthenticationManager
    private let containerController = ContainerViewController()

    init(manager: AuthenticationManager) {
        self.manager = manager

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(navigationController != nil, "PasscodeSettingsFlowController must be shown within navigation stack")

        title = manager.authenticationTitle

        view.backgroundColor = Styles.Colors.secondaryBackground

        containerController.view.backgroundColor = view.backgroundColor
        embedChild(containerController)

        let passcode = manager.passcode

        #if SCREENSHOT
            if CommandLine.isDemoMode {
                let pin = Pin(value: "1234", option: .fourDigits)
                // swiftlint:disable:next force_try
                try! passcode.save(newPin: pin)

                UserDefaults.standard.set(true, forKey: AppDomain + ".biometrics-authentication-enabled")

                showPinSettings()
            }
            else {
                if passcode.hasPin {
                    let controller = RequestPinViewController(manager: passcode)
                    controller.delegate = self
                    containerController.content = controller
                }
                else {
                    showPinSettings()
                }
            }
        #else
            if passcode.hasPin {
                let controller = RequestPinViewController(manager: passcode)
                controller.delegate = self
                containerController.content = controller
            }
            else {
                showPinSettings()
            }
        #endif /* SCREENSHOT */
    }

    // MARK: Private

    private func showPinSettings() {
        let controller = PinSettingsViewController(manager: manager)
        controller.delegate = self
        containerController.content = controller
    }
}

extension PasscodeSettingsFlowController: PinControllerDelegate {
    func pinControllerDidAuthorize(_ controller: PinController) {
        showPinSettings()
    }
}

extension PasscodeSettingsFlowController: PinSettingsViewControllerDelegate {
    func pinSettingsViewControllerDeletePin(_ controller: PinSettingsViewController, sender: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let turnOffAction = UIAlertAction(title: LocalizedStrings.turnPasscodeOff, style: .destructive) { _ in
            do {
                try self.manager.passcode.deletePin()
            }
            catch {
                self.display(error)
            }
            controller.reloadForm()
        }
        actionSheet.addAction(turnOffAction)

        let cancelAction = UIAlertAction(title: LocalizedStrings.cancel, style: .cancel)
        actionSheet.addAction(cancelAction)

        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        }

        present(actionSheet, animated: true)
    }

    func pinSettingsViewControllerSetupPin(_ controller: PinSettingsViewController) {
        manager.isSettingUpANewPin = true

        let controller = SetupPinViewController(defaultOption: .sixDigits, target: .passcode)
        controller.title = LocalizedStrings.setUpAppPasscode
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension PasscodeSettingsFlowController: SetupPinViewControllerDelegate {
    func setupPinViewController(_ controller: SetupPinViewController, didSetPin value: String) {
        do {
            let pin = Pin(value: value, option: controller.option)
            try manager.passcode.save(newPin: pin)
        }
        catch {
            display(error)
        }
        navigationController?.popViewController(animated: true)
    }

    func setupPinViewControllerDidFinish(_ controller: SetupPinViewController) {
        manager.isSettingUpANewPin = false
    }
}
