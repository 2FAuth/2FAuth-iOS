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

final class PinLabelView: UIView {
    var text: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
            isHidden = newValue == nil
            setNeedsLayout()
        }
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let style: PinLabelStyle

    init(style: PinLabelStyle) {
        self.style = style

        super.init(frame: .zero)

        backgroundColor = style.backgroundColor
        label.backgroundColor = backgroundColor
        label.textColor = style.textColor

        addSubview(label)

        let vertical = Styles.Sizes.smallPadding
        let horizontal = DeviceType.current.horizontalPadding
        let insets = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        label.pin(edges: self, insets: insets)

        if style == .error {
            layer.masksToBounds = true

            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self,
                                           selector: #selector(contentSizeCategoryDidChangeNotification),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateCornerRadiusIfNeeded()
    }

    // MARK: Notifications

    @objc
    private func contentSizeCategoryDidChangeNotification() {
        updateCornerRadiusIfNeeded()
    }

    // MARK: Private

    private func updateCornerRadiusIfNeeded() {
        guard style == .error else { return }
        layer.cornerRadius = bounds.height / 2
    }
}

// MARK: PinLabelStyle UI Parameters

private extension PinLabelStyle {
    var backgroundColor: UIColor {
        switch self {
        case .normal:
            return Styles.Colors.secondaryBackground
        case .error:
            return Styles.Colors.red
        }
    }

    var textColor: UIColor {
        switch self {
        case .normal:
            return Styles.Colors.label
        case .error:
            return Styles.Colors.lightText
        }
    }
}
