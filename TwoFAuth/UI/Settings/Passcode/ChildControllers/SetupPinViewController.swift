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

protocol SetupPinViewControllerDelegate: AnyObject {
    func setupPinViewController(_ controller: SetupPinViewController, didSetPin value: String)
    func setupPinViewControllerDidFinish(_ controller: SetupPinViewController)
}

final class SetupPinViewController: BasePinViewController {
    enum Target {
        case passcode
        case cloudPassphrase
    }

    var option: PinOption {
        didSet {
            setPinView.option = option
            verifyPinView.option = option
        }
    }

    weak var delegate: SetupPinViewControllerDelegate?

    private let target: Target

    private lazy var setPinView: PinView = {
        let title: String
        switch target {
        case .passcode:
            title = LocalizedStrings.enterYourNewPasscode
        case .cloudPassphrase:
            title = LocalizedStrings.enterYourCloudPassphrase
        }
        let pinView = PinView(option: option, title: title, hintLabelStyle: .normal)
        pinView.translatesAutoresizingMaskIntoConstraints = false
        switch target {
        case .passcode:
            pinView.optionsButton.setTitle(LocalizedStrings.passcodeOptions, for: .normal)
        case .cloudPassphrase:
            pinView.optionsButton.setTitle(LocalizedStrings.passphraseOptions, for: .normal)
        }
        pinView.optionsButton.addTarget(self, action: #selector(optionsButtonAction(_:)), for: .touchUpInside)
        pinView.pinField.delegate = self
        return pinView
    }()

    private lazy var verifyPinView: PinView = {
        let title: String
        switch target {
        case .passcode:
            title = LocalizedStrings.verifyYourNewPasscode
        case .cloudPassphrase:
            title = LocalizedStrings.verifyYourCloudPassphrase
        }
        let pinView = PinView(option: option, title: title, hintLabelStyle: .normal)
        pinView.translatesAutoresizingMaskIntoConstraints = false
        pinView.optionsButton.isHidden = true
        pinView.pinField.delegate = self
        return pinView
    }()

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = Styles.Colors.secondaryBackground
        return contentView
    }()

    private let feedbackGenerator = UINotificationFeedbackGenerator()

    init(defaultOption: PinOption, target: Target) {
        option = defaultOption
        self.target = target

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        showOrHideNextButton()

        verifyPinView.isHidden = true
        contentView.addSubview(setPinView)
        contentView.addSubview(verifyPinView)
        view.addSubview(contentView)

        let bottomConstraint = view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        pinViewBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            setPinView.topAnchor.constraint(equalTo: contentView.topAnchor),
            setPinView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: setPinView.bottomAnchor),
            setPinView.widthAnchor.constraint(equalTo: contentView.widthAnchor),

            verifyPinView.topAnchor.constraint(equalTo: contentView.topAnchor),
            verifyPinView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: verifyPinView.bottomAnchor),
            verifyPinView.widthAnchor.constraint(equalTo: contentView.widthAnchor),

            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomConstraint,
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !setPinView.isHidden {
            setPinView.pinField.activateCurrentField()
        }
        else if !verifyPinView.isHidden {
            verifyPinView.pinField.activateCurrentField()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent {
            delegate?.setupPinViewControllerDidFinish(self)
        }
    }

    // MARK: Private

    @objc
    private func optionsButtonAction(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let options = PinOption.allCases.filter { $0 != option }
        for option in options {
            let action = UIAlertAction(title: option.title, style: .default) { _ in
                self.option = option
                self.setPinView.pinField.activateCurrentField()
                self.showOrHideNextButton()
            }
            actionSheet.addAction(action)
        }

        let cancelAction = UIAlertAction(title: LocalizedStrings.cancel, style: .cancel)
        actionSheet.addAction(cancelAction)

        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        }

        present(actionSheet, animated: true)
    }

    private func switchFromPinView(_ fromPinView: PinView,
                                   toPinView: PinView,
                                   animateToTheLeft: Bool, completion: (() -> Void)? = nil) {
        assert(toPinView.isHidden)

        fromPinView.pinField.inputEnabled = false
        toPinView.pinField.inputEnabled = false

        let fromLeadingConstraint = fromPinView.findConstraint(layoutAttribute: .leading)
        let toLeadingConstraint = toPinView.findConstraint(layoutAttribute: .leading)

        let width = contentView.bounds.width
        toLeadingConstraint?.constant = animateToTheLeft ? width : -width
        view.layoutIfNeeded()
        toPinView.isHidden = false

        fromPinView.pinField.deactivateCurrentField()
        toPinView.pinField.activateCurrentField()

        fromLeadingConstraint?.constant = animateToTheLeft ? -width : width
        toLeadingConstraint?.constant = 0

        UIView.animate(
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                fromPinView.pinField.inputEnabled = true
                toPinView.pinField.inputEnabled = true

                fromPinView.isHidden = true

                completion?()
            }
        )
    }

    private func showOrHideNextButton() {
        if option == .alphanumeric {
            let button = UIBarButtonItem(title: LocalizedStrings.next,
                                         style: .done,
                                         target: self,
                                         action: #selector(nextButtonAction))
            navigationItem.rightBarButtonItem = button
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc
    private func nextButtonAction() {
        if !setPinView.isHidden {
            pinInputViewDidFinishInput(setPinView.pinField)
        }
        else if !verifyPinView.isHidden {
            pinInputViewDidFinishInput(verifyPinView.pinField)
        }
    }
}

extension SetupPinViewController: PinInputViewDelegate {
    func pinInputViewWillFinishInput(_ pinInputView: PinInputView) {}

    func pinInputViewDidFinishInput(_ pinInputView: PinInputView) {
        guard !pinInputView.text.isEmpty else {
            feedbackGenerator.notificationOccurred(.error)
            pinInputView.shake()

            return
        }

        if pinInputView == setPinView.pinField {
            switchFromPinView(setPinView, toPinView: verifyPinView, animateToTheLeft: true)
        }
        else if pinInputView == verifyPinView.pinField {
            let firstPin = setPinView.pinField.text
            let secondPin = verifyPinView.pinField.text

            if firstPin == secondPin {
                feedbackGenerator.notificationOccurred(.success)
                delegate?.setupPinViewController(self, didSetPin: firstPin)
            }
            else {
                feedbackGenerator.notificationOccurred(.error)

                setPinView.pinField.clear()
                setPinView.hint = LocalizedStrings.passcodesDidntMatch

                switchFromPinView(verifyPinView,
                                  toPinView: setPinView,
                                  animateToTheLeft: false,
                                  completion: {
                                      self.verifyPinView.pinField.clear()
                })
            }
        }
    }
}

extension PinOption {
    var title: String {
        switch self {
        case .fourDigits:
            return LocalizedStrings.fourDigitNumericCode
        case .sixDigits:
            return LocalizedStrings.sixDigitNumericCode
        case .alphanumeric:
            return LocalizedStrings.customAlphanumericCode
        }
    }
}
