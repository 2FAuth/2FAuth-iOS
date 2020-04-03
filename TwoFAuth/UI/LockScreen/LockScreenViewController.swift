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

final class LockScreenViewController: PinController {
    private let manager: AuthenticationManager

    override var contentView: UIView? {
        (view as! UIVisualEffectView).contentView
    }

    private let inputController: LockScreenInputViewController
    private var didEnterBackground = false

    init(manager: AuthenticationManager) {
        self.manager = manager

        let passcode = manager.passcode
        guard let pin = passcode.pin else {
            fatalError("Pin is not set. Check whether `hasPin` in advance")
        }
        let inputController = LockScreenInputViewController(option: pin.option,
                                                            biometricsIcon: manager.biometricsIcon)
        let statusController = PinLockdownViewController(style: .lockscreen)
        self.inputController = inputController

        super.init(manager: passcode, inputController: inputController, statusController: statusController)
    }

    override func updateStatus() {
        super.updateStatus()

        inputController.biometricsButton.isHidden = manager.isBiometricsAllowed == false
    }

    override func pinCheckFailed() {
        inputController.shakeLockIcon()
    }

    // MARK: Life Cycle

    override func loadView() {
        let blurEffect = UIBlurEffect(style: Styles.Misc.lockBlurStyle)
        view = UIVisualEffectView(effect: blurEffect)
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        inputController.biometricsButton.addTarget(self,
                                                   action: #selector(authorizeUsingBiometricsIfAllowed),
                                                   for: .touchUpInside)

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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        authorizeUsingBiometricsIfAllowed()
    }

    // MARK: Private

    @objc
    private func authorizeUsingBiometricsIfAllowed() {
        if !manager.isBiometricsAllowed {
            return
        }

        manager.authenticateUsingBiometrics { authorized in
            if authorized {
                self.feedbackGenerator.notificationOccurred(.success)

                self.delegate?.pinControllerDidAuthorize(self)
            }
        }
    }
}

extension LockScreenViewController {
    @objc
    private func didEnterBackgroundNotification() {
        didEnterBackground = true
    }

    @objc
    private func didBecomeActiveNotification() {
        if !didEnterBackground {
            return
        }
        didEnterBackground = false

        authorizeUsingBiometricsIfAllowed()
    }
}
