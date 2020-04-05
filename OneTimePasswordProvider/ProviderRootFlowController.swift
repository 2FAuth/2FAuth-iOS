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

import MobileCoreServices
import UIKit

final class ProviderRootFlowController: RootFlowController {
    private let services: Services
    private let context: NSExtensionContext?
    private let model: MainModel

    init(services: Services, context: NSExtensionContext?) {
        self.services = services
        self.context = context

        model = MainModel(storage: services.storage)

        let controller = ProviderMainFlowController(favIconFetcher: services.favIconFetcher, model: model)

        super.init(authManager: services.authManager, mainController: controller)

        fetchHostQueryFromCurrentContext { [weak self] hostQuery in
            guard let self = self else { return }
            self.model.matchQuery = hostQuery
        }

        controller.delegate = self
        controller.navigationItem.leftBarButtonItem = createCancelButton()
    }

    override func showInitialLockScreen() {
        if authManager.passcode.hasPin {
            let lockController = LockScreenViewController(manager: authManager)
            lockController.delegate = self
            embedChild(lockController)

            assert(lockController.contentView != nil)
            if let contentView = lockController.contentView {
                let cancelButton = createCancelButton(useCloseIcon: false)
                let toolbar = UIToolbar()
                toolbar.tintColor = Styles.Colors.secondaryTint
                toolbar.translatesAutoresizingMaskIntoConstraints = false
                toolbar.items = [cancelButton]
                // transparent toolbar
                toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
                toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
                contentView.addSubview(toolbar)

                let guide = contentView.layoutMarginsGuide
                NSLayoutConstraint.activate([
                    toolbar.topAnchor.constraint(equalTo: guide.topAnchor),
                    toolbar.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                    guide.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
                ])
            }

            self.lockController = lockController
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func showSubsequentLockScreen() {
        // same as initial
        showInitialLockScreen()
    }

    override func hideLockScreen(controller: UIViewController) {
        let duration = Styles.Animations.defaultDuration
        transition(from: controller, in: view, duration: duration)
        lockController = nil
        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: Private

    @objc
    private func cancelAction() {
        guard let context = context else {
            return
        }

        context.completeRequest(returningItems: nil)
    }

    private func createCancelButton(useCloseIcon: Bool = true) -> UIBarButtonItem {
        let systemItem: UIBarButtonItem.SystemItem
        if #available(iOS 13.0, *) {
            systemItem = useCloseIcon ? .close : .cancel
        }
        else {
            systemItem = .cancel
        }
        return UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(cancelAction))
    }

    /// Fetch a host string (e.g., 'github.com') from the context
    /// - Parameter hostQueryIfFound: called once **only** in case baseURI param is found (first matched)
    private func fetchHostQueryFromCurrentContext(hostQueryIfFound: @escaping (String?) -> Void) {
        guard let inputItems = context?.inputItems as? [NSExtensionItem] else {
            return
        }

        var reported = false

        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else {
                return
            }

            for itemProvider in attachments where itemProvider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil) { result, _ in
                    if let resultDict = result as? NSDictionary,
                        let results = resultDict[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary,
                        let urlString = results["baseURI"] as? String,
                        let url = URL(string: urlString),
                        let host = url.host {
                        if !reported {
                            var hostItems = host.split(separator: ".")
                            // ignore top level domain
                            if hostItems.count > 1 {
                                hostItems = hostItems.dropLast()
                            }
                            let hostQuery = hostItems.joined(separator: " ")

                            DispatchQueue.main.async {
                                hostQueryIfFound(hostQuery)
                            }

                            reported = true
                        }
                    }
                }
            }
        }
    }
}

extension ProviderRootFlowController: ProviderMainFlowControllerDeleagate {
    func didSelect(oneTimePassword: OneTimePassword) {
        guard let context = context else {
            return
        }

        let password = oneTimePassword.plainCode()

        let item = NSExtensionItem()
        let contents: NSDictionary = [
            NSExtensionJavaScriptFinalizeArgumentKey: ["password": password],
        ]
        let passwordItemProvider = NSItemProvider(item: contents, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [passwordItemProvider]
        context.completeRequest(returningItems: [item])
    }
}
