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

final class SettingsViewController: UIViewController {
    private let services: AppServices

    private let userDefaults: UserDefaults
    private let authManager: AuthenticationManager

    init(services: AppServices) {
        self.services = services
        userDefaults = services.userDefaults
        authManager = services.authManager

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var formController = GroupedFormTableViewController()

    private var cloudKitItem: SelectorFormCellModel {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.iCloudBackup
        model.detail = userDefaults.isCloudBackupEnabled ? LocalizedStrings.on : LocalizedStrings.off
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }

            let controller = CloudSettingsViewController(userDefaults: self.userDefaults,
                                                         storage: self.services.storage,
                                                         cloudPassphrase: self.services.cloudPassphrase,
                                                         cloudConfig: self.services.cloudConfig)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return model
    }

    private var passcodeItem: SelectorFormCellModel {
        let model = SelectorFormCellModel()
        model.accessibilityIdentifier = "settings.passcode"
        model.title = authManager.authenticationTitle
        model.detail = authManager.passcode.hasPin ? LocalizedStrings.on : LocalizedStrings.off
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }

            let controller = PasscodeSettingsFlowController(manager: self.authManager)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return model
    }

    private var manageItem: SelectorFormCellModel {
        let model = SelectorFormCellModel()
        model.accessibilityIdentifier = "settings.manage-otp"
        model.title = LocalizedStrings.manageOneTimePasswords
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }

            let controller = PasswordManagerFlowController(storage: self.services.storage,
                                                           userDefaults: self.userDefaults,
                                                           favIconFetcher: self.services.favIconFetcher)
            controller.title = LocalizedStrings.manageOneTimePasswords
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return model
    }

    private lazy var acknowledgementsItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.acknowledgements
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }

            let controller = TextViewController(filename: "Acknowledgements", fileType: "txt")
            controller.title = LocalizedStrings.acknowledgements
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return model
    }()

    private lazy var aboutItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.about
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }

            let controller = AboutViewController()
            controller.title = LocalizedStrings.about
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return model
    }()

    private var formSections: [FormSectionModel] {
        let firstSection = FormSectionModel([cloudKitItem, passcodeItem, manageItem])
        let secondSection = FormSectionModel([acknowledgementsItem, aboutItem])
        return [firstSection, secondSection]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = LocalizedStrings.settings

        view.backgroundColor = Styles.Colors.secondaryBackground

        embedChild(formController)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // reload data
        formController.setSections(formSections)
    }
}
