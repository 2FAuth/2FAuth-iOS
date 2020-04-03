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

protocol AddOTPViewControllerDelegate: AnyObject {
    func addOTPViewControllerDidCancel(_ controller: UIViewController)
    func addOTPViewController(_ controller: UIViewController, didAddToken token: Token)
}

final class AddOTPViewController: UIViewController {
    weak var delegate: AddOTPViewControllerDelegate?

    private let favIconFetcher: FavIconFetcher
    private var visualEffectView: UIVisualEffectView { view as! UIVisualEffectView }
    private var contentView: UIView { visualEffectView.contentView }

    override func loadView() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.frame = UIScreen.main.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view = visualEffectView
    }

    init(favIconFetcher: FavIconFetcher) {
        self.favIconFetcher = favIconFetcher

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChild(scanQRController, in: contentView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ProcessInfo().operatingSystemVersion.majorVersion < 13 {
            return .lightContent
        }
        else {
            assert(modalPresentationCapturesStatusBarAppearance == false,
                   "On iOS 13+ preferredStatusBarStyle should not be called")
            return .default
        }
    }

    // MARK: Private

    @objc
    private func enterManuallyBarButtonItemAction() {
        performTransition(toViewController: enterManuallyController, inContentView: contentView)
    }

    private var scanQRController: UIViewController {
        let enterManuallyBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(enterManuallyBarButtonItemAction)
        )

        let controller = AddOTPCameraViewController()
        controller.navigationItem.rightBarButtonItem = enterManuallyBarButtonItem
        controller.delegate = self
        return AddOTPNavigationController(rootViewController: controller)
    }

    private var enterManuallyController: UIViewController {
        let controller = AddOTPManualViewController(favIconFetcher: favIconFetcher)
        controller.delegate = self
        return AddOTPNavigationController(rootViewController: controller)
    }
}

extension AddOTPViewController: AddOTPViewControllerDelegate {
    func addOTPViewControllerDidCancel(_ controller: UIViewController) {
        delegate?.addOTPViewControllerDidCancel(self)
    }

    func addOTPViewController(_ controller: UIViewController, didAddToken token: Token) {
        delegate?.addOTPViewController(self, didAddToken: token)
    }
}

private extension AddOTPViewController {
    func performTransition(toViewController toController: UIViewController,
                           inContentView contentView: UIView,
                           withInsets insets: UIEdgeInsets = .zero) {
        guard let fromController = children.first else {
            preconditionFailure("Children is empty. Use displayController() instead")
        }

        guard let toView = toController.view,
            let fromView = fromController.view else { return }

        fromController.willMove(toParent: nil)
        addChild(toController)

        toView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toView)

        NSLayoutConstraint.activate([
            toView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
            toView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
            contentView.bottomAnchor.constraint(equalTo: toView.bottomAnchor, constant: insets.bottom),
            contentView.trailingAnchor.constraint(equalTo: toView.trailingAnchor, constant: insets.right),
        ])

        toView.alpha = 0.0
        toView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)

        UIView.animate(
            animations: {
                toView.alpha = 1.0
                toView.transform = CGAffineTransform.identity
                fromView.alpha = 0.0
            }, completion: { _ in
                fromView.removeFromSuperview()
                fromController.removeFromParent()
                toController.didMove(toParent: self)
            }
        )
    }
}
