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

class FormHeaderViewController: UIViewController {
    private(set) lazy var formController: FormTableViewController = {
        GroupedFormTableViewController()
    }()

    private(set) lazy var headerView: ImageDescriptionView = {
        let headerView = ImageDescriptionView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.preservesSuperviewLayoutMargins = true
        return headerView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.secondaryBackground

        embedChild(formController)
        formController.tableView.tableHeaderView = headerView
        headerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(contentSizeCategoryDidChangeNotification),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateHeaderViewHeight()
    }

    // MARK: Private

    private func updateHeaderViewHeight() {
        if let headerView = formController.tableView.tableHeaderView {
            let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if headerView.bounds.height != size.height {
                var frame = headerView.frame
                frame.size = size
                headerView.frame = frame
                formController.tableView.tableHeaderView = headerView
            }
        }
    }

    @objc
    private func contentSizeCategoryDidChangeNotification() {
        updateHeaderViewHeight()
    }
}
