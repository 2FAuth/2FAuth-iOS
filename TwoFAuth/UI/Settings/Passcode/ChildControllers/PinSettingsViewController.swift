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

protocol PinSettingsViewControllerDelegate: AnyObject {
    func pinSettingsViewControllerDeletePin(_ controller: PinSettingsViewController, sender: UIView)
    func pinSettingsViewControllerSetupPin(_ controller: PinSettingsViewController)
}

final class PinSettingsViewController: FormHeaderViewController {
    weak var delegate: PinSettingsViewControllerDelegate?

    private let manager: AuthenticationManager

    private lazy var turnOnPasscode: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.turnPasscodeOn
        model.titleStyle = .tinted
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.pinSettingsViewControllerSetupPin(self)
        }
        return model
    }()

    private lazy var turnOffPasscode: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.turnPasscodeOff
        model.titleStyle = .tinted
        model.action = { [weak self] cell in
            guard let self = self else { return }
            self.delegate?.pinSettingsViewControllerDeletePin(self, sender: cell)
        }
        return model
    }()

    private lazy var changePasscode: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.changePasscode
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.pinSettingsViewControllerSetupPin(self)
        }
        return model
    }()

    private var biometrics: SwitcherFormCellModel {
        let model = SwitcherFormCellModel()
        model.title = manager.biometricsOptionTitle
        model.isOn = manager.isBiometricsEnabled
        model.action = { [weak self] model, _ in
            guard let self = self else { return }
            if model.isOn {
                self.manager.authenticateUsingBiometrics { success in
                    self.manager.isBiometricsEnabled = success

                    if !success {
                        model.isOn = false
                    }
                }
            }
            else {
                self.manager.isBiometricsEnabled = false
            }
        }

        return model
    }

    private var formSections: [FormSectionModel] {
        let hasPin = manager.passcode.hasPin
        let items: [FormCellModel]
        if hasPin {
            items = [turnOffPasscode, changePasscode]
        }
        else {
            items = [turnOnPasscode]
        }

        let firstSection = FormSectionModel(items)

        let sections: [FormSectionModel]

        if hasPin && manager.isBiometricsAvailable {
            let secondSection = FormSectionModel([biometrics])
            sections = [firstSection, secondSection]
        }
        else {
            sections = [firstSection]
        }

        return sections
    }

    init(manager: AuthenticationManager) {
        self.manager = manager

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadForm() {
        formController.setSections(formSections)
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.image = Styles.Images.lockShield
        headerView.descriptionText = LocalizedStrings.setupPasscodeDescription
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadForm()
    }
}
