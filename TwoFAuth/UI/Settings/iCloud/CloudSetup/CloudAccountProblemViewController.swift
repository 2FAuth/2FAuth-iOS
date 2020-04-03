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

protocol CloudAccountProblemViewControllerDelegate: AnyObject {
    func cloudAccountProblemDidResolve()
}

final class CloudAccountProblemViewController: FormHeaderViewController {
    weak var delegate: CloudAccountProblemViewControllerDelegate?

    private var error: Error {
        didSet {
            headerView.descriptionText = error.userDescription
        }
    }

    private var checkingCloudStatus = false

    private lazy var settingsItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.settings
        model.titleStyle = .tinted
        model.accessoryType = .disclosureIndicator
        model.action = { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(url)
        }
        return model
    }()

    private var formSections: [FormSectionModel] {
        let firstSection = FormSectionModel([settingsItem])
        return [firstSection]
    }

    init(error: Error) {
        self.error = error

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.image = Styles.Images.cloudNoAccount
        headerView.descriptionText = error.userDescription

        formController.setSections(formSections)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(accountDidChange(_:)),
                                       name: .CKAccountChanged,
                                       object: nil)
    }

    // MARK: Private

    @objc
    private func accountDidChange(_ notification: Notification) {
        assert(!Thread.isMainThread)
        DispatchQueue.main.async {
            if self.checkingCloudStatus {
                return
            }
            self.checkingCloudStatus = true

            CKContainer.default().accountStatus { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if let error = error {
                        self.error = error
                    }
                    else {
                        self.delegate?.cloudAccountProblemDidResolve()
                    }

                    self.checkingCloudStatus = false
                }
            }
        }
    }
}
