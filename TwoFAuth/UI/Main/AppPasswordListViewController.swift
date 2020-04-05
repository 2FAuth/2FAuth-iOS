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

protocol PasswordListViewControllerEditDelegate: AnyObject {
    func editPersistentToken(_ persistentToken: PersistentToken)
}

final class AppPasswordListViewController: PasswordListViewController, PasswordManaging {
    weak var editDelegate: PasswordListViewControllerEditDelegate?

    let userDefaults: UserDefaults
    let storage: Storage

    init(storage: Storage, userDefaults: UserDefaults, favIconFetcher: FavIconFetcher) {
        self.storage = storage
        self.userDefaults = userDefaults

        super.init(favIconFetcher: favIconFetcher)
    }

    override func performDiffReload(old: MainDataSource, new: MainDataSource, update: () -> Void) {
        assert(new.sections.count <= 1, "AppPasswordListViewController doesn't support multiple sections diff reload")

        guard new.sections.count > 1 else {
            update()
            return
        }

        guard let oldItems = old.sections.first?.items, let newItems = new.sections.first?.items else {
            update()
            return
        }

        let changes = diff(old: oldItems, new: newItems)
        if changes.isEmpty {
            update()
        }
        else {
            tableView.reload(changes: changes, updateData: update)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if ProcessInfo().operatingSystemVersion.majorVersion < 13 {
            let gestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                 action: #selector(longPressGestureRecognizerAction(_:)))
            gestureRecognizer.minimumPressDuration = 1
            tableView.addGestureRecognizer(gestureRecognizer)
        }
    }

    // MARK: Private

    @objc
    private func longPressGestureRecognizerAction(_ sender: UIGestureRecognizer) {
        guard sender.state == .began else { return }

        let point = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
            let cell = tableView.cellForRow(at: indexPath) as? OneTimePasswordCell,
            let persistentToken = cell.oneTimePassword?.persistentToken else { return }

        editDelegate?.editPersistentToken(persistentToken)
    }
}

// MARK: UITableViewDelegate

extension AppPasswordListViewController {
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? OneTimePasswordCell,
            let persistentToken = cell.oneTimePassword?.persistentToken else {
            return nil
        }

        let edit = UIAction(title: LocalizedStrings.edit,
                            image: UIImage(systemName: "square.and.pencil")) { _ in
            self.editDelegate?.editPersistentToken(persistentToken)
        }

        let delete = UIAction(title: LocalizedStrings.delete,
                              image: UIImage(systemName: "trash"),
                              attributes: [.destructive]) { _ in
            self.delete(persistentToken, sender: cell)
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [edit, delete])
        }
    }
}
