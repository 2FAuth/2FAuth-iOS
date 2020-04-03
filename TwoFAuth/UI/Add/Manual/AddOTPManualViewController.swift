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

private let factorItems = [Generator.Factor.timer(period: 30), .counter(0)]
private let digitsItems = [GeneratorDigits.six, .seven, .eight]
private let algorithmItems = [Generator.Algorithm.sha1, .sha256, .sha512]

final class AddOTPManualViewController: UIViewController {
    weak var delegate: AddOTPViewControllerDelegate?
    private let favIconFetcher: FavIconFetcher

    init(favIconFetcher: FavIconFetcher) {
        self.favIconFetcher = favIconFetcher

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var formController = TransparentFormTableViewController()

    private lazy var iconImageView: UIImageView = {
        let iconSize = Styles.Sizes.iconSize
        let frame = CGRect(x: 0.0, y: 0.0, width: iconSize.width, height: iconSize.height)
        let iconImageView = UIImageView(frame: frame)
        iconImageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = Styles.Images.issuerPlaceholder
        return iconImageView
    }()

    private lazy var issuer: TextFieldFormCellModel = {
        let issuer = TextFieldFormCellModel()
        issuer.configureAsIssuerInput()
        issuer.title = LocalizedStrings.issuer
        issuer.placeholder = LocalizedStrings.website
        issuer.keyboardAppearance = .dark
        issuer.returnKeyType = .next
        issuer.didChangeText = { [weak self] _ in
            self?.updateIssuerIconIfNeeded()
            self?.didChangeText()
        }
        return issuer
    }()

    private lazy var accountName: TextFieldFormCellModel = {
        let accountName = TextFieldFormCellModel()
        accountName.configureAsAccountNameInput()
        accountName.title = LocalizedStrings.accountName
        accountName.placeholder = LocalizedStrings.accountNamePlaceholder
        accountName.keyboardAppearance = .dark
        accountName.returnKeyType = .next
        accountName.didChangeText = { [weak self] _ in
            self?.didChangeText()
        }
        return accountName
    }()

    private lazy var secretKey: TextFieldFormCellModel = {
        let secretKey = TextFieldFormCellModel()
        secretKey.title = LocalizedStrings.secretKey
        secretKey.placeholder = "•••• •••• •••• ••••"
        secretKey.autocapitalizationType = .none
        secretKey.autocorrectionType = .no
        secretKey.keyboardAppearance = .dark
        secretKey.returnKeyType = .done
        secretKey.validateAction = { [weak self] _ in
            self?.validate() ?? false
        }
        secretKey.didChangeText = { [weak self] _ in
            self?.didChangeText()
        }
        return secretKey
    }()

    private lazy var basicItems = [issuer, accountName, secretKey]

    private lazy var showAdvancedItems: [SelectorFormCellModel] = {
        let showAdvanced = SelectorFormCellModel()
        showAdvanced.title = LocalizedStrings.advancedOptions
        showAdvanced.action = { [weak self] _ in
            guard let self = self else { return }

            self.showAdvancedSection()
        }
        return [showAdvanced]
    }()

    private lazy var factor: SegmentedFormCellModel = {
        let factor = SegmentedFormCellModel()
        factor.items = factorItems
        return factor
    }()

    private lazy var digits: SegmentedFormCellModel = {
        let digits = SegmentedFormCellModel()
        digits.items = digitsItems
        return digits
    }()

    private lazy var algorithm: SegmentedFormCellModel = {
        let algorithm = SegmentedFormCellModel()
        algorithm.items = algorithmItems
        return algorithm
    }()

    private lazy var advancedItems = [factor, digits, algorithm]

    private var formSections: [FormSectionModel] {
        var sections = [FormSectionModel]()
        sections.append(FormSectionModel(basicItems))
        sections.append(FormSectionModel(showAdvancedItems))

        if advancedOptionsVisible {
            sections.append(FormSectionModel(advancedItems))
        }
        return sections
    }

    private var advancedOptionsVisible: Bool = false
    private let updateIconDebouncer = Debouncer.forUpdatingIssuerIcon()
    private var fetchIconOperation: FavIconCancellationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(cancelAction))
        navigationItem.leftBarButtonItem = cancelButton

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(doneAction))
        doneButton.isEnabled = false
        navigationItem.rightBarButtonItem = doneButton

        let iconContentView = UIView(frame: iconImageView.bounds)
        iconContentView.addSubview(iconImageView)
        navigationItem.titleView = iconContentView

        formController.setSections(formSections)

        // Manually embed form controller and pin its top and bottom constraints to the safe area guide

        addChild(formController)
        guard let childView = formController.view else {
            fatalError("Invalid UIViewController - view is nil")
        }
        childView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childView)

        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: childView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: childView.bottomAnchor),
        ])

        formController.didMove(toParent: self)
    }

    // MARK: Private

    @objc
    private func cancelAction() {
        delegate?.addOTPViewControllerDidCancel(self)
    }

    @objc
    private func doneAction() {
        guard let secretData = MF_Base32Codec.data(fromBase32String: secretKey.text),
            let generator = createGenerator(with: secretData) else {
            return
        }

        let token = Token(name: accountName.text, issuer: issuer.text, generator: generator)
        delegate?.addOTPViewController(self, didAddToken: token)
    }

    private func showAdvancedSection() {
        guard advancedOptionsVisible == false else {
            // don't allow to hide advanced options
            return
        }

        if let showAdvancedItem = showAdvancedItems.first {
            showAdvancedItem.isEnabled = false
        }

        advancedOptionsVisible = true

        formController.setSections(formSections, shouldReload: false)

        formController.tableView.performBatchUpdates({
            let section = IndexSet(integer: 2)
            self.formController.tableView.insertSections(section, with: .fade)
        }, completion: nil)
    }

    private func validate(shouldShowInvalidInput: Bool = true) -> Bool {
        guard let secretData = MF_Base32Codec.data(fromBase32String: secretKey.text),
            !secretData.isEmpty,
            createGenerator(with: secretData) != nil else {
            if shouldShowInvalidInput {
                formController.showInvalidInputForModel(secretKey)
            }

            return false
        }

        let isIssuerOrAccountNameValid = !(issuer.text.isEmpty && accountName.text.isEmpty)
        if !isIssuerOrAccountNameValid {
            if shouldShowInvalidInput {
                formController.showInvalidInputForModel(issuer)
                formController.showInvalidInputForModel(accountName)
            }

            return false
        }

        return true
    }

    private func createGenerator(with secretData: Data) -> Generator? {
        let factorValue = factorItems[factor.selectedIndex]
        let digitCount = digitsItems[digits.selectedIndex]
        let algorithmValue = algorithmItems[algorithm.selectedIndex]

        return Generator(factor: factorValue,
                         secret: secretData,
                         algorithm: algorithmValue,
                         digits: digitCount.rawValue)
    }

    private func didChangeText() {
        guard let doneButton = navigationItem.rightBarButtonItem else { return }
        doneButton.isEnabled = validate(shouldShowInvalidInput: false)
    }

    private func updateIssuerIconIfNeeded() {
        updateIconDebouncer.action = { [weak self] in
            guard let self = self else { return }

            self.fetchIconOperation?.cancel()

            let issuer = self.issuer.text
            self.fetchIconOperation = self.favIconFetcher.favicon(
                for: issuer,
                iconCompletion: { [weak self] image in
                    self?.iconImageView.image = image ?? Styles.Images.issuerPlaceholder
                }
            )
        }
    }
}

// MARK: - CustomStringConvertible

extension Generator.Factor: CustomStringConvertible {
    public var description: String {
        switch self {
        case .timer:
            return LocalizedStrings.timeBased
        case .counter:
            return LocalizedStrings.counterBased
        }
    }
}

private enum GeneratorDigits: Int, CustomStringConvertible {
    case six = 6
    case seven = 7
    case eight = 8

    var description: String {
        switch self {
        case .six:
            return LocalizedStrings.sixDigits
        case .seven:
            return LocalizedStrings.sevenDigits
        case .eight:
            return LocalizedStrings.eightDigits
        }
    }
}

extension Generator.Algorithm: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sha1:
            return "SHA-1"
        case .sha256:
            return "SHA-256"
        case .sha512:
            return "SHA-512"
        }
    }
}
