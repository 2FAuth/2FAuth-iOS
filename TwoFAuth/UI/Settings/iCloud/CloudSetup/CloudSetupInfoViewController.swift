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

protocol CloudSetupInfoViewControllerDelegate: AnyObject {
    func cloudSetupInfoViewControllerContinue()
}

final class CloudSetupInfoViewController: FormHeaderViewController {
    weak var delegate: CloudSetupInfoViewControllerDelegate?

    private lazy var setupItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.setupCloudPassphrase
        model.titleStyle = .tinted
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.cloudSetupInfoViewControllerContinue()
        }
        return model
    }()

    private var formSections: [FormSectionModel] {
        let firstSection = FormSectionModel([setupItem])
        return [firstSection]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.image = Styles.Images.cloud
        headerView.descriptionText = LocalizedStrings.setupCloudDescription

        formController.setSections(formSections)
    }
}
