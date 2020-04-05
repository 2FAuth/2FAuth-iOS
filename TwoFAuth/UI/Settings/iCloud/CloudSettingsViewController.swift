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

import CloudSync
import UIKit

final class CloudSettingsViewController: FormHeaderViewController, CloudManager {
    let storage: SyncableStorage

    private let userDefaults: UserDefaults
    private let cloudPassphrase: PinManager
    private let cloudConfig: CloudSync.Configuration

    init(userDefaults: UserDefaults,
         storage: SyncableStorage,
         cloudPassphrase: PinManager,
         cloudConfig: CloudSync.Configuration) {
        self.userDefaults = userDefaults
        self.storage = storage
        self.cloudPassphrase = cloudPassphrase
        self.cloudConfig = cloudConfig

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cloudKitEnabled: SwitcherFormCellModel {
        let model = SwitcherFormCellModel()
        model.title = LocalizedStrings.iCloudBackup
        model.isOn = userDefaults.isCloudBackupEnabled
        model.action = { [weak self] model, cell in
            guard let self = self else { return }

            if model.isOn {
                self.enaleCloudSync()
            }
            else {
                self.disableCloudSync(sender: cell, cancelCompletion: {
                    self.reloadForm()
                })
            }
        }
        return model
    }

    private var formSections: [FormSectionModel] {
        let firstSection = FormSectionModel([cloudKitEnabled])
        if userDefaults.isCloudBackupEnabled {
            firstSection.footer = LocalizedStrings.passphraseConfiguredDescription
        }
        return [firstSection]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = LocalizedStrings.iCloudBackup

        headerView.image = Styles.Images.cloud
        headerView.descriptionText = LocalizedStrings.iCloudBackupDescription

        reloadForm()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(reloadForm),
                                       name: UserDefaults.cloudBackupEnabledDidChangeNotification,
                                       object: nil)
    }

    // MARK: Private

    @objc
    private func reloadForm() {
        formController.setSections(formSections)
    }

    private func enaleCloudSync() {
        if cloudPassphrase.hasPin {
            storage.enableSync()
        }
        else {
            let controller = CloudSetupFlowController(storage: storage,
                                                      cloudPassphrase: cloudPassphrase,
                                                      cloudConfig: cloudConfig)
            controller.delegate = self
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true)
        }
    }
}

extension CloudSettingsViewController: CloudSetupFlowControllerDelegate {
    func cloudSetupFlowDidSetup(_ controller: CloudSetupFlowController) {
        reloadForm()
        controller.dismiss(animated: true) {
            self.storage.enableSync()
        }
    }

    func cloudSetupFlowDidCancel(_ controller: CloudSetupFlowController) {
        reloadForm()
        controller.dismiss(animated: true)
    }
}
