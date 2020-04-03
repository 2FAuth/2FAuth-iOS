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

class MainFlowController: UIViewController, MainDataSourceControllerDelegate {
    let model: MainModel
    let favIconFetcher: FavIconFetcher

    lazy var emptyController = EmptyPasswordsViewController()

    private var content: UIViewController? {
        didSet {
            transition(from: oldValue, to: content)
        }
    }

    private lazy var listController: MainDataSourceController = {
        let controller = createMainDataSourceController()
        controller.delegate = self
        return controller
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        return controller
    }()

    private lazy var titleView: NavigationTitleView = {
        let titleView = NavigationTitleView(frame: .zero)
        titleView.sizeToFit()
        return titleView
    }()

    init(favIconFetcher: FavIconFetcher, model: MainModel) {
        self.favIconFetcher = favIconFetcher
        self.model = model

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        model.stopUpdates()
    }

    func createMainDataSourceController() -> MainDataSourceController {
        PasswordListViewController(favIconFetcher: favIconFetcher)
    }

    func controllerForPresentingAlert() -> UIViewController? {
        self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.background

        definesPresentationContext = true
        navigationItem.titleView = titleView

        updateContentController()

        // start off the model
        model.delegate = self
        model.update()
    }

    // MARK: PasswordListViewControllerDelegate

    func didSelect(oneTimePassword: OneTimePassword) {
        // NOP
    }

    func nextPassword(for oneTimePassword: OneTimePassword) {
        model.nextPassword(for: oneTimePassword)
    }

    // MARK: Private

    private func updateContentController() {
        if model.isEmpty {
            content = emptyController
            navigationItem.searchController = nil
        }
        else {
            navigationItem.searchController = searchController
            content = listController
        }
    }
}

// MARK: MainModelDelegate

extension MainFlowController: MainModelDelegate {
    func mainModel(_ model: MainModel, didUpdateDataSource dataSource: MainDataSource) {
        updateContentController()

        listController.update(dataSource)
        titleView.update(with: dataSource.progressModel)
    }

    func mainModel(_ model: MainModel, showAlertWithTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: LocalizedStrings.ok, style: .cancel)
        alert.addAction(action)
        guard let presentingController = controllerForPresentingAlert() else {
            assert(false, "Cannot find topmost controller")
            return
        }
        presentingController.present(alert, animated: true)
    }
}

// MARK: UISearchResultsUpdating

extension MainFlowController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        model.searchQuery = searchController.searchBar.text
    }
}
