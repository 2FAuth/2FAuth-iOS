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

import MessageUI
import StoreKit
import UIKit

final class AboutViewController: UIViewController {
    private static let github = "https://github.com/2FAuth/2FAuth-iOS"
    private static let copyright = "© 2020 Andrew Podkovyrin."
    private static let email = "podkovyrin@gmail.com"

    private lazy var headerView: UIView = {
        guard let iconImage = Bundle.main.icon else {
            assert(false, "App Icon is not available")
            return UIView()
        }

        let imageSize = iconImage.size
        let backgroundColor = Styles.Colors.secondaryBackground

        let headerView = UIView()
        headerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerView.backgroundColor = backgroundColor

        let smoothingView = SmoothingCornersView()
        smoothingView.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        smoothingView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        smoothingView.backgroundColor = backgroundColor
        smoothingView.cornerRadius = 114.0 / 512.0 * imageSize.width
        headerView.addSubview(smoothingView)

        let imageView = UIImageView(image: iconImage)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.backgroundColor = backgroundColor
        imageView.contentMode = .center
        smoothingView.addSubview(imageView)

        return headerView
    }()

    private lazy var formController = GroupedFormTableViewController()

    private lazy var githubItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = Self.github
        model.titleStyle = .tinted
        model.action = { _ in
            guard let url = URL(string: Self.github) else {
                assert(false, "Invalid github URL")
                return
            }

            UIApplication.shared.open(url)
        }
        return model
    }()

    private lazy var reviewItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.rate2FAuth
        model.titleStyle = .tinted
        model.action = { _ in
            SKStoreReviewController.requestReview()
        }
        return model
    }()

    private lazy var contactUsItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.contactUs
        model.action = { [weak self] _ in
            guard let self = self else { return }

            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([Self.email])
                self.present(mail, animated: true)
            }
        }
        return model
    }()

    private lazy var privacyPolicyItem: SelectorFormCellModel = {
        let model = SelectorFormCellModel()
        model.title = LocalizedStrings.privacyPolicy
        model.accessoryType = .disclosureIndicator
        model.action = { [weak self] _ in
            guard let self = self else { return }

            let controller = TextViewController(filename: "PrivacyPolicy", fileType: "txt")
            controller.title = LocalizedStrings.privacyPolicy
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return model
    }()

    private var formSections: [FormSectionModel] {
        let firstSection = FormSectionModel([githubItem])
        firstSection.footer = LocalizedStrings.thisAppIsOpenSource

        var items = [reviewItem]
        if MFMailComposeViewController.canSendMail() {
            items.append(contactUsItem)
        }
        items.append(privacyPolicyItem)

        let secondSection = FormSectionModel(items)

        let dictionary = Bundle.main.infoDictionary!
        let versionValue = dictionary["CFBundleShortVersionString"] ?? "0"
        let buildValue = dictionary["CFBundleVersion"] ?? "0"
        secondSection.footer = "\(Self.copyright) \(LocalizedStrings.appName) v\(versionValue) (\(buildValue))"

        return [firstSection, secondSection]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.secondaryBackground

        embedChild(formController)
        formController.setSections(formSections)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let tableView = formController.tableView else { return }
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 200)
        tableView.tableHeaderView = headerView
    }
}

extension AboutViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
