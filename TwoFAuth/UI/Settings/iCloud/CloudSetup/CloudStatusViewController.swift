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

final class CloudStatusViewController: UIViewController {
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .large)
        }
        else {
            activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        }
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.color = Styles.Colors.label
        return activityIndicatorView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Styles.Colors.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = LocalizedStrings.enablingCloudBackup
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.secondaryBackground

        let stackView = UIStackView(arrangedSubviews: [activityIndicatorView, titleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Styles.Sizes.xLargePadding
        view.addSubview(stackView)

        let marginsGuide = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: marginsGuide.leadingAnchor),
            marginsGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicatorView.startAnimating()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        activityIndicatorView.stopAnimating()
    }
}
