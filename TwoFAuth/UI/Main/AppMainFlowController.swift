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

import DeepDiff

import UIKit

final class AppMainFlowController: MainFlowController {
    weak var delegate: AddOneTimePasswordDelegate? {
        get { emptyController.delegate }
        set { emptyController.delegate = newValue }
    }

    let userDefaults: UserDefaults
    let storage: Storage

    init(storage: Storage, userDefaults: UserDefaults, favIconFetcher: FavIconFetcher, model: MainModel) {
        self.storage = storage
        self.userDefaults = userDefaults

        super.init(favIconFetcher: favIconFetcher, model: model)
    }

    override func createMainDataSourceController() -> MainDataSourceController {
        AppPasswordListViewController(storage: storage, userDefaults: userDefaults, favIconFetcher: favIconFetcher)
    }

    override func controllerForPresentingAlert() -> UIViewController? {
        UIApplication.topmostController()
    }

    // MARK: PasswordListViewControllerDelegate

    override func didSelect(oneTimePassword: OneTimePassword) {
        model.copyPassword(for: oneTimePassword)
    }
}

// MARK: PasswordListViewControllerEditDelegate

extension AppMainFlowController: PasswordListViewControllerEditDelegate {
    func editPersistentToken(_ persistentToken: PersistentToken) {
        let controller = PasswordManagerFlowController(storage: storage,
                                                       userDefaults: userDefaults,
                                                       favIconFetcher: favIconFetcher)
        controller.title = LocalizedStrings.manageOneTimePasswords
        controller.targetPersistentToken = persistentToken

        let systemItem: UIBarButtonItem.SystemItem
        if #available(iOS 13.0, *) {
            systemItem = .close
        }
        else {
            systemItem = .cancel
        }
        let closeButton = UIBarButtonItem(barButtonSystemItem: systemItem,
                                          target: self,
                                          action: #selector(dismissPasswordManagerController))
        controller.navigationItem.leftBarButtonItem = closeButton

        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    @objc
    private func dismissPasswordManagerController() {
        dismiss(animated: true)
    }
}
