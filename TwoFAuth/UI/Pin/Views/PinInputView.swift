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

protocol PinInputViewDelegate: AnyObject {
    func pinInputViewWillFinishInput(_ pinInputView: PinInputView)
    func pinInputViewDidFinishInput(_ pinInputView: PinInputView)
}

final class PinInputView: UIView {
    enum Style {
        case settings
        case lockScreen
    }

    weak var delegate: PinInputViewDelegate?

    var option: PinOption {
        didSet {
            switch option {
            case .fourDigits, .sixDigits:
                textField.text = nil
                digitsField.option = option
            case .alphanumeric:
                digitsField.clear()
            }

            UIView.animate(withDuration: Styles.Animations.defaultDuration) {
                self.updateAppearanceForCurrentOption()
                self.invalidateIntrinsicContentSize()
            }
        }
    }

    var text: String {
        switch option {
        case .fourDigits, .sixDigits:
            return digitsField.text
        case .alphanumeric:
            return textField.text ?? ""
        }
    }

    var inputEnabled = true {
        didSet {
            digitsField.inputEnabled = inputEnabled
        }
    }

    var digitsTextInput: UITextInput {
        digitsField
    }

    private let digitsField: NumericPinField
    private let textField: UITextField
    private var topLineView: UIView?
    private var bottomLineView: UIView?

    init(option: PinOption, style: Style) {
        self.option = option

        switch style {
        case .settings:
            digitsField = NumericPinField(dotStyle: .normal)
            textField = InsetsTextField(horizontalInset: Styles.Sizes.xLargePadding)
        case .lockScreen:
            digitsField = NumericPinField(dotStyle: .small)
            textField = UITextField(frame: .zero)
        }

        super.init(frame: .zero)

        backgroundColor = .clear

        digitsField.translatesAutoresizingMaskIntoConstraints = false
        digitsField.delegate = self
        addSubview(digitsField)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        addSubview(textField)

        let textFieldPadding: CGFloat
        switch style {
        case .settings:
            textFieldPadding = 0

            textField.backgroundColor = Styles.Colors.background
            textField.textColor = Styles.Colors.label

            let visible = option == .alphanumeric

            let topLineView = Self.dividerView()
            topLineView.alpha = visible ? 1 : 0
            addSubview(topLineView)
            self.topLineView = topLineView

            let bottomLineView = Self.dividerView()
            bottomLineView.alpha = visible ? 1 : 0
            addSubview(bottomLineView)
            self.bottomLineView = bottomLineView

            let height: CGFloat = 1.0 / UIScreen.main.scale
            NSLayoutConstraint.activate([
                topLineView.topAnchor.constraint(equalTo: topAnchor),
                topLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: topLineView.trailingAnchor),
                topLineView.heightAnchor.constraint(equalToConstant: height),

                bottomLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
                bottomAnchor.constraint(equalTo: bottomLineView.bottomAnchor),
                trailingAnchor.constraint(equalTo: bottomLineView.trailingAnchor),
                bottomLineView.heightAnchor.constraint(equalToConstant: height),
            ])
        case .lockScreen:
            textFieldPadding = Styles.Sizes.xLargePadding

            textField.tintColor = Styles.Colors.secondaryTint
            textField.backgroundColor = .clear
            textField.textColor = Styles.Colors.lightText
            textField.textAlignment = .center
            textField.layer.cornerRadius = 8
            textField.layer.masksToBounds = true
            textField.layer.borderColor = Styles.Colors.lightText.withAlphaComponent(0.75).cgColor
            textField.layer.borderWidth = 1.0 / UIScreen.main.scale
        }

        NSLayoutConstraint.activate([
            digitsField.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: digitsField.bottomAnchor),
            digitsField.centerXAnchor.constraint(equalTo: centerXAnchor),
            digitsField.centerYAnchor.constraint(equalTo: centerYAnchor),

            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textFieldPadding),
            bottomAnchor.constraint(equalTo: textField.bottomAnchor),
            trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: textFieldPadding),
        ])

        updateAppearanceForCurrentOption()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clear() {
        switch option {
        case .fourDigits, .sixDigits:
            digitsField.clear()
        case .alphanumeric:
            textField.text = nil
        }
    }

    func activateCurrentField() {
        switch option {
        case .fourDigits, .sixDigits:
            _ = digitsField.becomeFirstResponder()
        case .alphanumeric:
            _ = textField.becomeFirstResponder()
        }
    }

    func deactivateCurrentField() {
        switch option {
        case .fourDigits, .sixDigits:
            _ = digitsField.resignFirstResponder()
        case .alphanumeric:
            _ = textField.becomeFirstResponder()
        }
    }

    func shake() {
        shakeView()
    }

    func enableAudioFeedbackInputViewIfNeeded() {
        switch option {
        case .fourDigits, .sixDigits:
            // inputView should have any valid frame
            digitsField.inputView = AudioFeedbackInputView(frame: CGRect(x: 0, y: 0, width: 320, height: 1))
        case .alphanumeric:
            break
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        // Clean up pin from memory once window's gone.
        if newWindow == nil {
            clear()
        }
    }

    override var intrinsicContentSize: CGSize {
        switch option {
        case .fourDigits, .sixDigits:
            return digitsField.intrinsicContentSize
        case .alphanumeric:
            return textField.intrinsicContentSize
        }
    }

    // MARK: Private

    private func updateAppearanceForCurrentOption() {
        switch self.option {
        case .fourDigits, .sixDigits:
            textField.alpha = 0
            topLineView?.alpha = 0
            bottomLineView?.alpha = 0
            digitsField.alpha = 1
        case .alphanumeric:
            digitsField.alpha = 0
            textField.alpha = 1
            topLineView?.alpha = 1
            bottomLineView?.alpha = 1
        }
    }
}

extension PinInputView: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        return inputEnabled
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return inputEnabled
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.pinInputViewDidFinishInput(self)
        return true
    }
}

extension PinInputView: NumericPinFieldDelegate {
    func numericPinFieldWillFinishInput(_ pinField: NumericPinField) {
        delegate?.pinInputViewWillFinishInput(self)
    }

    func numericPinFieldDidFinishInput(_ pinField: NumericPinField) {
        delegate?.pinInputViewDidFinishInput(self)
    }
}

// MARK: Private

extension PinInputView {
    class func dividerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Styles.Colors.divider
        return view
    }
}
