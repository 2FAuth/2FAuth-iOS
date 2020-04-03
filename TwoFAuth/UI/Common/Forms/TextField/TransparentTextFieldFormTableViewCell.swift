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

final class TransparentTextFieldFormTableViewCell: UITableViewCell, TextFieldFormTableViewCell {
    var model: TextFieldFormCellModel? {
        didSet {
            guard let model = model else { return }

            accessibilityIdentifier = model.accessibilityIdentifier

            titleLabel.text = model.title

            textField.text = model.text
            textField.placeholder = model.placeholder

            textField.autocapitalizationType = model.autocapitalizationType
            textField.autocorrectionType = model.autocorrectionType
            textField.spellCheckingType = model.spellCheckingType
            textField.smartQuotesType = model.smartQuotesType
            textField.smartDashesType = model.smartDashesType
            textField.smartInsertDeleteType = model.smartInsertDeleteType
            textField.keyboardType = model.keyboardType
            textField.keyboardAppearance = model.keyboardAppearance
            textField.returnKeyType = model.returnKeyType
            textField.enablesReturnKeyAutomatically = model.enablesReturnKeyAutomatically
            textField.isSecureTextEntry = model.isSecureTextEntry
            textField.textContentType = model.textContentType
        }
    }

    weak var delegate: TextFieldFormTableViewCellDelegate?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Styles.Colors.lightText
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = Styles.Colors.background
        textField.textColor = Styles.Colors.label
        textField.borderStyle = .roundedRect
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.delegate = self
        return textField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = backgroundColor

        contentView.addSubview(titleLabel)
        contentView.addSubview(textField)

        titleLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)

        let guide = contentView.layoutMarginsGuide

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                           constant: Styles.Sizes.mediumPadding),
            textField.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            guide.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textFieldBecomeFirstResponder() {
        textField.becomeFirstResponder()
    }
}

extension TransparentTextFieldFormTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let nsStringText = textField.text as NSString?
        model?.text = nsStringText?.replacingCharacters(in: range, with: string) as String? ?? ""

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        model?.text = ""
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next {
            delegate?.textFieldFormTableViewCellActivateNextFirstResponder(self)
        }
        else if textField.returnKeyType == .done {
            var valid = true
            if let model = model, let validateAction = model.validateAction {
                valid = validateAction(model.text)
            }

            if valid {
                endEditing(true)
            }
        }

        return true
    }
}
