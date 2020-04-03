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

final class LockScreenInputViewController: UIViewController, PinInputController {
    weak var pinFieldDelegate: PinInputViewDelegate?

    var attemptsLeft: UInt? {
        didSet {
            if let attempts = attemptsLeft {
                attemptsLabel.isHidden = false
                attemptsLabel.text = LocalizedStrings.attemptsLeft(attempts)
            }
            else {
                attemptsLabel.isHidden = true
                attemptsLabel.text = nil
            }
        }
    }

    private(set) lazy var biometricsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Styles.Colors.secondaryTint
        button.setImage(biometricsIcon, for: .normal)
        return button
    }()

    private let option: PinOption
    private let biometricsIcon: UIImage?

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: Styles.Images.lockIcon)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = Styles.Colors.secondaryTint
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Styles.Colors.lightText
        label.font = .systemFont(ofSize: 22)
        label.textAlignment = .center
        label.text = LocalizedStrings.enterAppPasscode
        return label
    }()

    private(set) lazy var pinField: PinInputView = {
        let pinField = PinInputView(option: option, style: .lockScreen)
        pinField.translatesAutoresizingMaskIntoConstraints = false
        pinField.delegate = self
        pinField.enableAudioFeedbackInputViewIfNeeded()
        pinField.option = option
        return pinField
    }()

    private(set) lazy var attemptsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Styles.Colors.lightText
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var keyboard: PinCodeKeyboardView = {
        let keyboard = PinCodeKeyboardView()
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        keyboard.textInput = pinField.digitsTextInput
        return keyboard
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.tintColor = Styles.Colors.secondaryTint
        button.setTitle(LocalizedStrings.delete, for: .normal)
        button.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
        return button
    }()

    private let pinFieldKeyboardPadding: CGFloat = DeviceType.current == .phoneSmall ? 44 : 64

    init(option: PinOption, biometricsIcon: UIImage?) {
        self.option = option
        self.biometricsIcon = biometricsIcon

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func shakeLockIcon() {
        let isIconShown = DeviceType.current != .phoneSmall
        if isIconShown {
            iconImageView.shakeView()
        }
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let isIconShown = DeviceType.current != .phoneSmall

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if isIconShown {
            contentView.addSubview(iconImageView)
        }
        contentView.addSubview(titleLabel)
        contentView.addSubview(pinField)
        contentView.addSubview(attemptsLabel)

        let isDigitsInput = option == .fourDigits || option == .sixDigits

        view.addSubview(contentView)

        if isDigitsInput {
            view.addSubview(keyboard)
        }

        view.addSubview(biometricsButton)

        if isDigitsInput {
            view.addSubview(deleteButton)
        }

        let marginsGuide = view.layoutMarginsGuide

        contentView.pin(horizontally: marginsGuide)
        titleLabel.pin(horizontally: contentView)
        attemptsLabel.pin(horizontally: contentView)

        if isIconShown {
            NSLayoutConstraint.activate([
                iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

                titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor,
                                                constant: Styles.Sizes.xLargePadding),
            ])
        }
        else {
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        }

        if isDigitsInput {
            NSLayoutConstraint.activate([
                contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                pinField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Styles.Sizes.xLargePadding),
                pinField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Styles.Sizes.largePadding),
                contentView.trailingAnchor.constraint(equalTo: pinField.trailingAnchor, constant: Styles.Sizes.largePadding),

                attemptsLabel.topAnchor.constraint(equalTo: pinField.bottomAnchor),
                keyboard.topAnchor.constraint(equalTo: attemptsLabel.bottomAnchor),

                keyboard.topAnchor.constraint(equalTo: pinField.bottomAnchor, constant: pinFieldKeyboardPadding),
                keyboard.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                contentView.bottomAnchor.constraint(equalTo: keyboard.bottomAnchor),

                biometricsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: biometricsButton.bottomAnchor,
                                                                 constant: Styles.Sizes.mediumPadding),
                biometricsButton.widthAnchor.constraint(equalToConstant: Styles.Sizes.buttonMinSize),
                biometricsButton.heightAnchor.constraint(equalToConstant: Styles.Sizes.buttonMinSize),

                deleteButton.trailingAnchor.constraint(equalTo: keyboard.trailingAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: deleteButton.bottomAnchor,
                                                                 constant: Styles.Sizes.mediumPadding),
                deleteButton.heightAnchor.constraint(equalToConstant: Styles.Sizes.buttonMinSize),
            ])
        }
        else {
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Styles.Sizes.xLargePadding),

                pinField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Styles.Sizes.xLargePadding),
                pinField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Styles.Sizes.largePadding),
                contentView.trailingAnchor.constraint(equalTo: pinField.trailingAnchor, constant: Styles.Sizes.largePadding),
                pinField.heightAnchor.constraint(equalToConstant: 34),

                attemptsLabel.topAnchor.constraint(equalTo: pinField.bottomAnchor, constant: Styles.Sizes.largePadding),

                biometricsButton.topAnchor.constraint(equalTo: attemptsLabel.bottomAnchor, constant: Styles.Sizes.xLargePadding),
                biometricsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contentView.bottomAnchor.constraint(equalTo: biometricsButton.bottomAnchor),
                biometricsButton.widthAnchor.constraint(equalToConstant: Styles.Sizes.buttonMinSize),
                biometricsButton.heightAnchor.constraint(equalToConstant: Styles.Sizes.buttonMinSize),
            ])
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        pinField.activateCurrentField()
    }

    // MARK: Private

    @objc
    private func deleteButtonAction() {
        UIDevice.current.playInputClick()
        pinField.digitsTextInput.deleteBackward()
    }
}

extension LockScreenInputViewController: PinInputViewDelegate {
    func pinInputViewWillFinishInput(_ pinInputView: PinInputView) {
        if option == .fourDigits || option == .sixDigits {
            keyboard.isUserInteractionEnabled = false
        }
        pinFieldDelegate?.pinInputViewWillFinishInput(pinInputView)
    }

    func pinInputViewDidFinishInput(_ pinInputView: PinInputView) {
        pinFieldDelegate?.pinInputViewDidFinishInput(pinInputView)
        if option == .fourDigits || option == .sixDigits {
            keyboard.isUserInteractionEnabled = true
        }
    }
}
