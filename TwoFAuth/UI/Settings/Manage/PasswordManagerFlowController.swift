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

class PasswordManagerFlowController: UIViewController {
    var targetPersistentToken: PersistentToken?

    private let storage: Storage
    private let userDefaults: UserDefaults
    private let favIconFetcher: FavIconFetcher

    private var content: UIViewController? {
        didSet {
            transition(from: oldValue, to: content)
        }
    }

    private lazy var managerController: PasswordManagerViewController = {
        let controller = PasswordManagerViewController(storage: storage,
                                                       userDefaults: userDefaults,
                                                       favIconFetcher: favIconFetcher)
        controller.targetPersistentToken = targetPersistentToken
        return controller
    }()

    private lazy var emptyController = EmptyPasswordsViewController()

    init(storage: Storage, userDefaults: UserDefaults, favIconFetcher: FavIconFetcher) {
        self.storage = storage
        self.userDefaults = userDefaults
        self.favIconFetcher = favIconFetcher

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.secondaryBackground

        updateContentController()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(storageDidUpdateNotification(_:)),
                                       name: StorageNotification.didUpdate,
                                       object: storage)
    }

    // MARK: Private

    @objc
    private func storageDidUpdateNotification(_ notification: Notification) {
        updateContentController()
    }

    private func updateContentController() {
        if storage.persistentTokens.isEmpty {
            content = emptyController
        }
        else {
            content = managerController
        }
    }
}
