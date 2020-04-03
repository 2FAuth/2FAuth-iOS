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

class BasePinViewController: UIViewController {
    var pinViewBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.secondaryBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterFromKeyboardNotifications()
    }
}

extension BasePinViewController: KeyboardStateDelegate {
    func keyboardWillTransition(_ state: KeyboardState) {
        switch state {
        case let .activeWithHeight(height):
            pinViewBottomConstraint?.constant = height
        case .hidden:
            // don't update layout when keyboard is hidden
            break
        }

        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }

    func keyboardDidTransition(_ state: KeyboardState) {}

    func keyboardTransitionAnimation(_ state: KeyboardState) {}
}
