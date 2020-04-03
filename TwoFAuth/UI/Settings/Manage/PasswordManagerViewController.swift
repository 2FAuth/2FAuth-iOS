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

final class PasswordManagerViewController: UITableViewController, PasswordManaging {
    var targetPersistentToken: PersistentToken?

    let storage: Storage
    let userDefaults: UserDefaults
    private let favIconFetcher: FavIconFetcher

    private var dataSource: [PersistentToken]
    private let cellIdentifier = String(describing: PasswordManagerTableViewCell.self)
    private lazy var measuringCell = PasswordManagerTableViewCell(style: .default, reuseIdentifier: nil)
    private var ignoreTableViewUpdates = false
    private var isEditingMode = false
    private var pendingEditModeIndexPath: IndexPath?

    init(storage: Storage, userDefaults: UserDefaults, favIconFetcher: FavIconFetcher) {
        self.storage = storage
        self.userDefaults = userDefaults
        self.favIconFetcher = favIconFetcher
        dataSource = storage.persistentTokens

        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isEditing = true

        tableView.allowsSelectionDuringEditing = true
        tableView.keyboardDismissMode = .onDrag
        tableView.register(PasswordManagerTableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(storageDidUpdateNotification(_:)),
                                       name: StorageNotification.didUpdate,
                                       object: storage)
        notificationCenter.addObserver(tableView as Any,
                                       selector: #selector(UITableView.reloadData),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterFromKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let persistentToken = targetPersistentToken {
            targetPersistentToken = nil

            if let row = dataSource.firstIndex(of: persistentToken) {
                let indexPath = IndexPath(row: row, section: 0)
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)

                if tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
                    guard let cell = tableView.cellForRow(at: indexPath) as? PasswordManagerTableViewCell else { return }
                    switchToEditingMode(with: cell)
                }
                else {
                    pendingEditModeIndexPath = indexPath
                }
            }
        }
    }

    // MARK: Notifications

    @objc
    private func storageDidUpdateNotification(_ notification: Notification) {
        if ignoreTableViewUpdates {
            dataSource = storage.persistentTokens
        }
        else {
            let changes = diff(old: dataSource, new: storage.persistentTokens)
            tableView.reload(changes: changes, updateData: {
                dataSource = storage.persistentTokens
            })
        }
    }

    // MARK: Private

    private func performWithoutTableViewUpdates(_ block: () -> Void) {
        ignoreTableViewUpdates = true
        block()
        ignoreTableViewUpdates = false
    }
}

// MARK: UITableViewDataSource

extension PasswordManagerViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            as? PasswordManagerTableViewCell else {
            preconditionFailure("invalid cell type")
        }

        let persistentToken = dataSource[indexPath.row]
        cell.favIconFetcher = favIconFetcher
        cell.delegate = self
        cell.persistentToken = persistentToken
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            guard let cell = tableView.cellForRow(at: indexPath) else {
                return
            }

            let persistentToken = dataSource[indexPath.row]
            delete(persistentToken, sender: cell)
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        performWithoutTableViewUpdates {
            storage.moveTokenFromIndex(source.row, toIndex: destination.row)
        }
    }
}

// MARK: UITableViewDelegate

extension PasswordManagerViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let persistentToken = dataSource[indexPath.row]

        measuringCell.frame = tableView.bounds
        measuringCell.persistentToken = persistentToken
        let fittingSize = CGSize(width: tableView.bounds.width, height: .greatestFiniteMagnitude)
        let height = measuringCell.sizeThatFits(fittingSize).height
        return height
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard let cell = tableView.cellForRow(at: indexPath) as? PasswordManagerTableViewCell else { return }
        switchToEditingMode(with: cell)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? PasswordManagerTableViewCell else { return }
        if !isEditingMode {
            cell.contentView.alpha = 1
        }
    }

    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}

// MARK: UIScrollViewDelegate

extension PasswordManagerViewController {
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let indexPath = pendingEditModeIndexPath else { return }

        pendingEditModeIndexPath = nil

        guard let cell = tableView.cellForRow(at: indexPath) as? PasswordManagerTableViewCell else { return }
        switchToEditingMode(with: cell)
    }
}

// MARK: Editing Mode

private extension PasswordManagerViewController {
    private static let inactiveCellAlpha: CGFloat = 0.25

    func switchToEditingMode(with activeCell: PasswordManagerTableViewCell) {
        isEditingMode = true

        activeCell.startEditing()
        activeCell.contentView.alpha = 1

        if let indexPath = tableView.indexPath(for: activeCell) {
            // defer scrolling for next runloop, to avoid intersection with built-in UITableView
            // scrolling behavior to the first responder
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        }

        UIView.animate(withDuration: Styles.Animations.defaultDuration) {
            for cell in self.tableView.visibleCells {
                guard let cell = cell as? PasswordManagerTableViewCell else { continue }
                if cell !== activeCell {
                    cell.stopEditing()
                    cell.contentView.alpha = Self.inactiveCellAlpha
                }
            }
        }

        if parent?.navigationItem.rightBarButtonItem == nil {
            let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(switchToNormalMode))
            parent?.navigationItem.setRightBarButton(button, animated: true)
        }
    }

    @objc
    func switchToNormalMode() {
        if !isEditingMode {
            return
        }
        isEditingMode = false

        UIView.animate(withDuration: Styles.Animations.defaultDuration) {
            for cell in self.tableView.visibleCells {
                guard let cell = cell as? PasswordManagerTableViewCell else { continue }
                cell.stopEditing()
                cell.contentView.alpha = 1

                self.performWithoutTableViewUpdates {
                    self.updatePersistentTokenIfChanged(from: cell)
                }
            }
        }

        if parent?.navigationItem.rightBarButtonItem != nil {
            parent?.navigationItem.setRightBarButton(nil, animated: true)
        }
    }

    private func updatePersistentTokenIfChanged(from cell: PasswordManagerTableViewCell) {
        guard let persistentToken = cell.persistentToken else { return }

        let updatedPersistentToken = persistentToken.update(issuer: cell.issuer, accountName: cell.accountName)
        if updatedPersistentToken.token != persistentToken.token {
            do {
                try storage.updatePersistentToken(updatedPersistentToken)
                cell.persistentToken = updatedPersistentToken
            }
            catch {
                display(error)
                cell.persistentToken = persistentToken
            }
        }
    }
}

// MARK: PasswordManagerTableViewCellDelegate

extension PasswordManagerViewController: PasswordManagerTableViewCellDelegate {
    func passwordManagerTableViewCell(didStartEditing cell: PasswordManagerTableViewCell) {
        switchToEditingMode(with: cell)
    }
}

// MARK: KeyboardStateDelegate

extension PasswordManagerViewController: KeyboardStateDelegate {
    func keyboardWillTransition(_ state: KeyboardState) {
        switch state {
        case .activeWithHeight:
            break
        case .hidden:
            switchToNormalMode()
        }
    }

    func keyboardDidTransition(_ state: KeyboardState) {}

    func keyboardTransitionAnimation(_ state: KeyboardState) {}
}
