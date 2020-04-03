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

protocol SettingsFlowControllerDelegate: AnyObject {
    func settingsFlowDidFinish(controller: SettingsFlowController)
}

final class SettingsFlowController: UIViewController {
    weak var delegate: SettingsFlowControllerDelegate?

    private let services: AppServices

    private lazy var rootNavigationController = {
        UINavigationController(rootViewController: settingsController)
    }()

    private lazy var settingsController: SettingsViewController = {
        let controller = SettingsViewController(services: services)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(cancelAction))
        controller.navigationItem.leftBarButtonItem = cancelButton
        return controller
    }()

    init(services: AppServices) {
        self.services = services

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChild(rootNavigationController)
    }
}

// MARK: Private

extension SettingsFlowController {
    @objc
    private func cancelAction() {
        delegate?.settingsFlowDidFinish(controller: self)
    }
}
