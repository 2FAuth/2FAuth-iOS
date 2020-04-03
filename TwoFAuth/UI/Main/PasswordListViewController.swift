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

protocol MainDataSourceControllerDelegate: AnyObject {
    func didSelect(oneTimePassword: OneTimePassword)
    func nextPassword(for oneTimePassword: OneTimePassword)
}

protocol MainDataSourceController: UIViewController {
    var delegate: MainDataSourceControllerDelegate? { get set }

    func update(_ dataSource: MainDataSource)
}

class PasswordListViewController: UITableViewController, MainDataSourceController {
    weak var delegate: MainDataSourceControllerDelegate?

    private var dataSource: MainDataSource?
    private let favIconFetcher: FavIconFetcher
    private let cellIdentifier = String(describing: OneTimePasswordCell.self)

    private lazy var measuringCell = OneTimePasswordCell(style: .default, reuseIdentifier: nil)
    private var cellHeightByPassword = [OneTimePassword: CGFloat]()

    private let feedbackGenerator = UISelectionFeedbackGenerator()

    init(favIconFetcher: FavIconFetcher) {
        self.favIconFetcher = favIconFetcher

        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ dataSource: MainDataSource) {
        cellHeightByPassword.removeAll()

        if isViewLoaded {
            // To prevent unwanted cell animation two OneTimePasswords considered equal if their persistent tokens
            // are the same. That's why we need to reloadData() after diffable reload which will update codes.
            let update = {
                self.dataSource = dataSource
                self.tableView.reloadData()
            }

            if let old = self.dataSource, !old.items.isEmpty, view.window != nil {
                performDiffReload(old: old, new: dataSource, update: update)
            }
            else {
                update()
            }
        }
        else {
            self.dataSource = dataSource
        }
    }

    func performDiffReload(old: MainDataSource, new: MainDataSource, update: () -> Void) {
        update()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = Styles.Colors.background
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.register(OneTimePasswordCell.self, forCellReuseIdentifier: cellIdentifier)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(contentSizeCategoryDidChangeNotification),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    // MARK: Notifications

    @objc
    private func contentSizeCategoryDidChangeNotification() {
        dataSource?.items.forEach { $0.resetFormattedValues() }
        cellHeightByPassword.removeAll()
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource

extension PasswordListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.items.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            as? OneTimePasswordCell else {
            preconditionFailure("invalid OneTimePassword cell type")
        }

        guard let oneTimePassword = dataSource?.items[indexPath.row] else {
            preconditionFailure("invalid dataSource")
        }

        cell.favIconFetcher = favIconFetcher
        cell.oneTimePassword = oneTimePassword
        cell.progressModel = dataSource?.progressModel
        cell.delegate = self
        return cell
    }
}

// MARK: UITableViewDelegate

extension PasswordListViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let oneTimePassword = dataSource?.items[indexPath.row] else {
            preconditionFailure("invalid dataSource")
        }

        if let height = cellHeightByPassword[oneTimePassword] {
            return height
        }

        measuringCell.frame = tableView.bounds
        measuringCell.oneTimePassword = oneTimePassword
        let fittingSize = CGSize(width: tableView.bounds.width, height: .greatestFiniteMagnitude)
        let height = measuringCell.sizeThatFits(fittingSize).height
        cellHeightByPassword[oneTimePassword] = height

        return height
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        feedbackGenerator.selectionChanged()

        guard let oneTimePassword = dataSource?.items[indexPath.row] else {
            preconditionFailure("invalid dataSource")
        }

        delegate?.didSelect(oneTimePassword: oneTimePassword)
    }
}

// MARK: OneTimePasswordCellDelegate

extension PasswordListViewController: OneTimePasswordCellDelegate {
    func oneTimePasswordCellNextPasswordAction(_ cell: OneTimePasswordCell) {
        if let oneTimePassword = cell.oneTimePassword {
            delegate?.nextPassword(for: oneTimePassword)
        }
    }
}
