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

final class RequestPinInputViewController: BasePinViewController, PinInputController {
    weak var pinFieldDelegate: PinInputViewDelegate? {
        get { pinView.pinField.delegate }
        set { pinView.pinField.delegate = newValue }
    }

    var attemptsLeft: UInt? {
        didSet {
            if let attempts = attemptsLeft {
                pinView.hint = LocalizedStrings.attemptsLeft(attempts)
            }
            else {
                pinView.hint = nil
            }
        }
    }

    private let option: PinOption

    private lazy var pinView: PinView = {
        let pinView = PinView(option: option, title: LocalizedStrings.enterAppPasscode, hintLabelStyle: .error)
        pinView.translatesAutoresizingMaskIntoConstraints = false
        pinView.optionsButton.isHidden = true
        return pinView
    }()

    init(option: PinOption) {
        self.option = option

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(pinView)

        let bottomConstraint = view.bottomAnchor.constraint(equalTo: pinView.bottomAnchor)
        pinViewBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            pinView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pinView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomConstraint,
            pinView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        pinView.pinField.activateCurrentField()
    }
}
