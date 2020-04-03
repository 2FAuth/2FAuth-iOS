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

protocol PinInputController: UIViewController {
    var pinFieldDelegate: PinInputViewDelegate? { get set }
    var attemptsLeft: UInt? { get set }
}

protocol PinControllerDelegate: AnyObject {
    func pinControllerDidAuthorize(_ controller: PinController)
}

class PinController: UIViewController {
    weak var delegate: PinControllerDelegate?

    var contentView: UIView? {
        nil
    }

    let feedbackGenerator = UINotificationFeedbackGenerator()

    private let manager: PinManager
    private let inputController: PinInputController
    private let statusController: PinLockdownViewController
    private let updateStatusInterval: TimeInterval = 1

    private var currentController: UIViewController? {
        didSet {
            transition(from: oldValue, to: currentController, in: contentView)
        }
    }

    init(manager: PinManager, inputController: PinInputController, statusController: PinLockdownViewController) {
        self.manager = manager
        self.inputController = inputController
        self.statusController = statusController

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStatus() {
        let status = manager.status()
        switch status {
        case .timer:
            fallthrough
        case .noSecureTime:
            let deadline = DispatchTime.now() + updateStatusInterval
            DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
                self?.updateStatus()
            }
        case .forever:
            break
        case .none:
            break
        }

        if let status = status {
            statusController.subtitleText = status.userMessage
            currentController = statusController
        }
        else {
            inputController.attemptsLeft = manager.attemptsLeft()
            currentController = inputController
        }
    }

    func pinCheckFailed() {
        // to be overriden
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        inputController.pinFieldDelegate = self
        updateStatus()
    }
}

extension PinController: PinInputViewDelegate {
    func pinInputViewWillFinishInput(_ pinInputView: PinInputView) {}

    func pinInputViewDidFinishInput(_ pinInputView: PinInputView) {
        let authorized = manager.check(pinInputView.text)
        updateStatus()

        if authorized {
            feedbackGenerator.notificationOccurred(.success)

            delegate?.pinControllerDidAuthorize(self)
        }
        else {
            feedbackGenerator.notificationOccurred(.error)

            pinInputView.clear()
            pinInputView.shake()

            pinCheckFailed()
        }
    }
}
