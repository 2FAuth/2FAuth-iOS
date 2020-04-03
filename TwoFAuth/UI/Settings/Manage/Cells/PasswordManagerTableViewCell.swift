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

protocol PasswordManagerTableViewCellDelegate: AnyObject {
    func passwordManagerTableViewCell(didStartEditing cell: PasswordManagerTableViewCell)
}

final class PasswordManagerTableViewCell: UITableViewCell {
    var persistentToken: PersistentToken? {
        didSet {
            updateCell(with: persistentToken)
        }
    }

    var issuer: String { issuerTextField.text ?? "" }
    var accountName: String { accountNameTextField.text ?? "" }

    private var isEditingMode = false

    weak var favIconFetcher: FavIconFetcher?
    weak var delegate: PasswordManagerTableViewCellDelegate?
    private lazy var updateIconDebouncer = Debouncer.forUpdatingIssuerIcon()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()

    private lazy var issuerTextField: UITextField = {
        let textField = InsetsTextField(horizontalInset: Styles.Sizes.smallPadding,
                                        verticalInset: Styles.Sizes.smallPadding)
        textField.configureAsIssuerInput()
        textField.delegate = self
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = Styles.Colors.label
        textField.returnKeyType = .next
        textField.placeholder = LocalizedStrings.website
        return textField
    }()

    private lazy var accountNameTextField: UITextField = {
        let textField = InsetsTextField(horizontalInset: Styles.Sizes.smallPadding,
                                        verticalInset: Styles.Sizes.smallPadding)
        textField.configureAsAccountNameInput()
        textField.delegate = self
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = Styles.Colors.secondaryLabel
        textField.returnKeyType = .done
        textField.placeholder = LocalizedStrings.accountNamePlaceholder
        return textField
    }()

    private var fetchIconOperation: FavIconCancellationToken?

    private var cellHeight: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        contentView.addSubview(iconImageView)
        contentView.addSubview(issuerTextField)
        contentView.addSubview(accountNameTextField)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(contentSizeCategoryDidChangeNotification),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        setNeedsLayout()
        layoutIfNeeded()
        return CGSize(width: size.width, height: min(cellHeight, size.height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margins = deviceSpecificMargins

        var x: CGFloat = margins.left
        var y: CGFloat = margins.top

        let iconSize = Styles.Sizes.iconSize
        iconImageView.frame = CGRect(x: x,
                                     y: (contentView.bounds.height - iconSize.height) / 2,
                                     width: iconSize.width,
                                     height: iconSize.height)
        x += iconSize.width + Styles.Sizes.largePadding

        let textFieldWidth = contentView.bounds.width - x - margins.right
        let maxTextFieldSize = CGSize(width: textFieldWidth, height: Styles.Sizes.uiElementMaxHeight)
        let issuerHeight = issuerTextField.sizeThatFits(maxTextFieldSize).height
        let accountNameHeight = accountNameTextField.sizeThatFits(maxTextFieldSize).height

        issuerTextField.frame = CGRect(x: x, y: y, width: textFieldWidth, height: issuerHeight)
        y += issuerHeight - UITextField.borderWidth

        accountNameTextField.frame = CGRect(x: x, y: y, width: textFieldWidth, height: accountNameHeight)
        y += accountNameHeight + margins.bottom

        cellHeight = y
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateTextFieldsBackgroundColorForEditingModeIfNeeded()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        reset()
    }

    func startEditing() {
        if isEditingMode {
            return
        }
        isEditingMode = true

        issuerTextField.showRoundedBorder(maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        accountNameTextField.showRoundedBorder(maskedCorners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])

        updateTextFieldsBackgroundColorForEditingModeIfNeeded()

        accountNameTextField.textColor = Styles.Colors.label

        if !accountNameTextField.isFirstResponder {
            _ = issuerTextField.becomeFirstResponder()
        }
    }

    func stopEditing() {
        if !isEditingMode {
            return
        }
        isEditingMode = false

        issuerTextField.hideRoundedBorder()
        accountNameTextField.hideRoundedBorder()

        UIView.performWithoutAnimation {
            issuerTextField.backgroundColor = .clear
            accountNameTextField.backgroundColor = .clear
        }

        accountNameTextField.textColor = Styles.Colors.secondaryLabel

        if issuerTextField.isFirstResponder {
            _ = issuerTextField.resignFirstResponder()
        }
        if accountNameTextField.isFirstResponder {
            _ = accountNameTextField.resignFirstResponder()
        }
    }

    // MARK: Notifications

    @objc
    private func contentSizeCategoryDidChangeNotification() {
        // Don't use textfield's `adjustsFontForContentSizeCategory` since it updates font too late
        // which results in a wrong cell height while switching Dynamic Type while on the screen.

        issuerTextField.font = .preferredFont(forTextStyle: .body)
        accountNameTextField.font = .preferredFont(forTextStyle: .body)
    }

    // MARK: Private

    private func updateCell(with persistentToken: PersistentToken?) {
        reset()

        stopEditing()

        guard let persistentToken = persistentToken else { return }

        let token = persistentToken.token
        issuerTextField.text = token.issuer
        accountNameTextField.text = token.name

        iconImageView.image = Styles.Images.issuerPlaceholder

        let issuer = persistentToken.token.issuer
        fetchIconOperation = favIconFetcher?.favicon(
            for: issuer,
            iconCompletion: { [weak self] image in
                guard let self = self else { return }
                if let image = image {
                    self.iconImageView.image = image
                }
            }
        )

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func updateIssuerIconIfNeeded() {
        updateIconDebouncer.action = { [weak self] in
            guard let self = self else { return }

            self.fetchIconOperation?.cancel()

            guard let issuer = self.issuerTextField.text else { return }
            self.fetchIconOperation = self.favIconFetcher?.favicon(
                for: issuer,
                iconCompletion: { [weak self] image in
                    self?.iconImageView.image = image ?? Styles.Images.issuerPlaceholder
                }
            )
        }
    }

    private func reset() {
        fetchIconOperation?.cancel()
        updateIconDebouncer.cancel()

        iconImageView.image = nil
        issuerTextField.text = nil
        accountNameTextField.text = nil
    }

    private func updateTextFieldsBackgroundColorForEditingModeIfNeeded() {
        guard isEditingMode else { return }

        if #available(iOS 13, *) {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            if isDarkMode {
                issuerTextField.backgroundColor = Styles.Colors.background
                accountNameTextField.backgroundColor = Styles.Colors.background
            }
        }
    }
}

extension PasswordManagerTableViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.passwordManagerTableViewCell(didStartEditing: self)
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField === issuerTextField {
            updateIssuerIconIfNeeded()
        }

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField === issuerTextField {
            updateIssuerIconIfNeeded()
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next {
            _ = accountNameTextField.becomeFirstResponder()
        }
        else if textField.returnKeyType == .done {
            endEditing(true)
        }

        return true
    }
}

private extension UITextField {
    static let borderWidth: CGFloat = 1

    func showRoundedBorder(maskedCorners: CACornerMask) {
        layer.cornerRadius = 4
        layer.maskedCorners = maskedCorners
        layer.masksToBounds = true
        layer.borderWidth = Self.borderWidth
        layer.borderColor = Styles.Colors.divider.cgColor
    }

    func hideRoundedBorder() {
        layer.cornerRadius = 0
        layer.maskedCorners = []
        layer.masksToBounds = false
        layer.borderWidth = 0
        layer.borderColor = nil
    }
}
