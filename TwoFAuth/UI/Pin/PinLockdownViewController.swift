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

final class PinLockdownViewController: UIViewController {
    enum Style {
        case lockscreen
        case settings
    }

    var subtitleText: String? {
        get { subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }

    private let style: Style

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = style == .lockscreen ? Styles.Colors.lightText : Styles.Colors.label
        label.font = .systemFont(ofSize: 36)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = LocalizedStrings.appIsDisabled
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = style == .lockscreen ? Styles.Colors.lightText : Styles.Colors.label
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(style: Style) {
        self.style = style

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Styles.Sizes.smallPadding
        stackView.alignment = .center
        view.addSubview(stackView)

        let marginsGuide = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: marginsGuide.leadingAnchor),
            marginsGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
