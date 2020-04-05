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

import CloudKit
import CloudSync
import UIKit

protocol CloudSetupFlowControllerDelegate: AnyObject {
    func cloudSetupFlowDidSetup(_ controller: CloudSetupFlowController)
    func cloudSetupFlowDidCancel(_ controller: CloudSetupFlowController)
}

final class CloudSetupFlowController: UIViewController, CloudManager {
    weak var delegate: CloudSetupFlowControllerDelegate?

    let storage: SyncableStorage

    private let cloudPassphrase: PinManager
    private let cloudProbe: CloudProbe

    private lazy var rootNavigationController = {
        UINavigationController()
    }()

    init(storage: SyncableStorage, cloudPassphrase: PinManager, cloudConfig: CloudSync.Configuration) {
        self.storage = storage
        self.cloudPassphrase = cloudPassphrase
        cloudProbe = CloudProbe(configuration: cloudConfig)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChild(rootNavigationController)

        CKContainer.default().accountStatus { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    let controller = CloudAccountProblemViewController(error: error)
                    controller.delegate = self
                    self.displayAsRootController(controller, animated: false)
                }
                else {
                    self.showInfoController(animated: false)
                }
            }
        }
    }
}

// MARK: Private

extension CloudSetupFlowController {
    private func showStatusAndTest(pin: Pin) {
        let controller = CloudStatusViewController()
        displayAsRootController(controller, animated: true)

        cloudProbe.test(passphrase: pin.value) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                do {
                    try self.cloudPassphrase.save(newPin: pin)
                    self.delegate?.cloudSetupFlowDidSetup(self)
                }
                catch {
                    self.display(error)
                }
            case let .failure(error):
                self.showPinSetupController()
                self.displayCloudProbeFailure(error)
            }
        }
    }

    private func showInfoController(animated: Bool) {
        let controller = CloudSetupInfoViewController()
        controller.delegate = self
        displayAsRootController(controller, animated: animated)
    }

    private func showPinSetupController() {
        let controller = SetupPinViewController(defaultOption: .alphanumeric, target: .cloudPassphrase)
        controller.delegate = self
        displayAsRootController(controller, animated: true)
    }

    private func displayAsRootController(_ controller: UIViewController, animated: Bool) {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                         target: self,
                                         action: #selector(cancelAction))
        controller.navigationItem.leftBarButtonItem = doneButton
        controller.title = LocalizedStrings.iCloudBackup
        rootNavigationController.setViewControllers([controller], animated: animated)
    }

    private func displayCloudProbeFailure(_ error: Error) {
        let alert = UIAlertController(error: error)
        let tryAgainAction = UIAlertAction(title: LocalizedStrings.tryAgain, style: .cancel)
        alert.addAction(tryAgainAction)

        let resetAction = UIAlertAction(title: LocalizedStrings.deleteDataFromCloud, style: .destructive) { _ in
            self.disableCloudSync(sender: nil)
        }
        alert.addAction(resetAction)

        alert.preferredAction = tryAgainAction

        present(alert, animated: true)
    }

    @objc
    private func cancelAction() {
        delegate?.cloudSetupFlowDidCancel(self)
    }
}

// MARK: Account Problem Delegate

extension CloudSetupFlowController: CloudAccountProblemViewControllerDelegate {
    func cloudAccountProblemDidResolve() {
        showInfoController(animated: true)
    }
}

// MARK: Info Delegate

extension CloudSetupFlowController: CloudSetupInfoViewControllerDelegate {
    func cloudSetupInfoViewControllerContinue() {
        showPinSetupController()
    }
}

// MARK: Setup Pin Delegate

extension CloudSetupFlowController: SetupPinViewControllerDelegate {
    func setupPinViewController(_ controller: SetupPinViewController, didSetPin value: String) {
        let pin = Pin(value: value, option: controller.option)
        showStatusAndTest(pin: pin)
    }

    func setupPinViewControllerDidFinish(_ controller: SetupPinViewController) {}
}
