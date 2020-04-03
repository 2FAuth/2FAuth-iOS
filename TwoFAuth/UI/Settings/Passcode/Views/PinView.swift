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

final class PinView: UIView {
    var hint: String? {
        get { hintView.text }
        set { hintView.text = newValue }
    }

    var option: PinOption {
        didSet {
            pinField.option = option
        }
    }

    let pinField: PinInputView
    let optionsButton = DynamicTypeButton(type: .system)

    private lazy var titleView: PinLabelView = {
        let labelView = PinLabelView(style: .normal)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        return labelView
    }()

    private let hintView: PinLabelView
    private let pinFieldHeightConstraint: NSLayoutConstraint

    private let padding: CGFloat = 30

    init(option: PinOption, title: String, hintLabelStyle: PinLabelStyle) {
        self.option = option

        hintView = PinLabelView(style: hintLabelStyle)
        hintView.translatesAutoresizingMaskIntoConstraints = false

        pinField = PinInputView(option: option, style: .settings)
        let pinHeight = Self.pinFieldHeight(for: UIApplication.shared.preferredContentSizeCategory)
        pinFieldHeightConstraint = pinField.heightAnchor.constraint(equalToConstant: pinHeight)

        super.init(frame: .zero)

        backgroundColor = Styles.Colors.secondaryBackground

        let titleContentView = UIView()
        titleContentView.translatesAutoresizingMaskIntoConstraints = false
        titleContentView.backgroundColor = backgroundColor
        addSubview(titleContentView)
        titleView.text = title
        titleContentView.addSubview(titleView)

        pinField.option = option
        pinField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pinField)

        let hintContentView = UIView()
        hintContentView.translatesAutoresizingMaskIntoConstraints = false
        hintContentView.backgroundColor = backgroundColor
        addSubview(hintContentView)
        hintContentView.addSubview(hintView)

        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.backgroundColor = backgroundColor
        optionsButton.tintColor = Styles.Colors.tint
        optionsButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        addSubview(optionsButton)

        titleContentView.setContentHuggingPriority(.fittingSizeLevel + 1, for: .vertical)
        hintContentView.setContentHuggingPriority(.fittingSizeLevel + 2, for: .vertical)
        pinField.setContentCompressionResistancePriority(.required, for: .vertical)
        pinField.setContentHuggingPriority(.required, for: .vertical)
        optionsButton.setContentHuggingPriority(.required - 1, for: .vertical)

        NSLayoutConstraint.activate([
            titleContentView.topAnchor.constraint(equalTo: topAnchor),
            titleContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: titleContentView.trailingAnchor),

            titleView.topAnchor.constraint(greaterThanOrEqualTo: titleContentView.topAnchor),
            titleView.leadingAnchor.constraint(greaterThanOrEqualTo: titleContentView.leadingAnchor),
            titleContentView.trailingAnchor.constraint(greaterThanOrEqualTo: titleView.trailingAnchor),
            titleContentView.bottomAnchor.constraint(equalTo: titleView.bottomAnchor),
            titleView.centerXAnchor.constraint(equalTo: titleContentView.centerXAnchor),

            pinField.topAnchor.constraint(equalTo: titleContentView.bottomAnchor, constant: padding),
            pinField.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: pinField.trailingAnchor),
            pinField.centerYAnchor.constraint(equalTo: centerYAnchor),
            pinFieldHeightConstraint,

            hintContentView.topAnchor.constraint(equalTo: pinField.bottomAnchor, constant: padding),
            hintContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: hintContentView.trailingAnchor),

            hintView.topAnchor.constraint(equalTo: hintContentView.topAnchor),
            hintView.leadingAnchor.constraint(greaterThanOrEqualTo: hintContentView.leadingAnchor),
            hintContentView.trailingAnchor.constraint(greaterThanOrEqualTo: hintView.trailingAnchor),
            hintContentView.bottomAnchor.constraint(greaterThanOrEqualTo: hintView.bottomAnchor),
            hintView.centerXAnchor.constraint(equalTo: hintContentView.centerXAnchor),

            optionsButton.topAnchor.constraint(equalTo: hintContentView.bottomAnchor),
            optionsButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: optionsButton.trailingAnchor),
            bottomAnchor.constraint(equalTo: optionsButton.bottomAnchor),
            optionsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Styles.Sizes.buttonMinSize),
        ])

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(contentSizeCategoryDidChangeNotification(_:)),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Notifications

    @objc
    private func contentSizeCategoryDidChangeNotification(_ notification: Notification) {
        if let category = notification.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory {
            pinFieldHeightConstraint.constant = Self.pinFieldHeight(for: category)
        }
    }
}

private extension PinView {
    class func pinFieldHeight(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraLarge:
            return 48
        case .extraExtraLarge:
            return 52
        case .extraExtraExtraLarge:
            return 58
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return 70
        default:
            return 44
        }
    }
}
