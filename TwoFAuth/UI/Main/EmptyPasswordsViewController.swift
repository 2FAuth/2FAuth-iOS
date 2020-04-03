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

final class EmptyPasswordsViewController: UIViewController {
    #if !APP_EXTENSION
        weak var delegate: AddOneTimePasswordDelegate?
    #endif /* !APP_EXTENSION */

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = Styles.Colors.label
        label.text = LocalizedStrings.noOneTimePasswords
        return label
    }()

    #if !APP_EXTENSION
        private lazy var addLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.numberOfLines = 0
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.isUserInteractionEnabled = true
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addAction))
            label.addGestureRecognizer(tapGestureRecognizer)
            return label
        }()
    #endif /* !APP_EXTENSION */

    override func viewDidLoad() {
        super.viewDidLoad()

        #if APP_EXTENSION
            let verticalStackView = UIStackView(arrangedSubviews: [titleLabel])
        #else
            updateButtonTitle()

            let verticalStackView = UIStackView(arrangedSubviews: [titleLabel, addLabel])
        #endif /* APP_EXTENSION */

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .center
        verticalStackView.spacing = Styles.Sizes.smallPadding

        let horizontalStackView = UIStackView(arrangedSubviews: [verticalStackView])
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(horizontalStackView)
        view.addSubview(scrollView)

        scrollView.pin(edges: view.layoutMarginsGuide)

        NSLayoutConstraint.activate([
            horizontalStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            horizontalStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            horizontalStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            horizontalStackView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
        ])

        #if !APP_EXTENSION
            addLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Styles.Sizes.buttonMinSize).isActive = true

            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self,
                                           selector: #selector(contentSizeCategoryDidChangeNotification),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
        #endif /* !APP_EXTENSION */
    }

    #if !APP_EXTENSION

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)

            updateButtonTitle()
        }

        // MARK: Private

        private func updateButtonTitle() {
            guard delegate != nil else {
                addLabel.isHidden = true
                return
            }

            let title = LocalizedStrings.tapPlusToAddANewOneTimePassword

            let regularFont = UIFont.preferredFont(forTextStyle: .body)
            let regularAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .foregroundColor: Styles.Colors.label,
            ]

            let attributedTitle = NSMutableAttributedString(string: title, attributes: regularAttributes)

            let plusRange = (title as NSString).range(of: "+")
            assert(plusRange.location != NSNotFound)
            if plusRange.location != NSNotFound {
                let plusAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: max(36, regularFont.pointSize), weight: .light),
                    .foregroundColor: Styles.Colors.tint,
                ]

                attributedTitle.setAttributes(plusAttributes, range: plusRange)
            }

            addLabel.attributedText = attributedTitle
        }

        @objc
        private func addAction() {
            delegate?.addOneTimePasswordAction()
        }

        @objc
        private func contentSizeCategoryDidChangeNotification() {
            updateButtonTitle()
        }

    #endif /* !APP_EXTENSION */
}
