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

final class RequestPinViewController: PinController {
    init(manager: PinManager) {
        guard let pin = manager.pin else {
            fatalError("Pin is not set. Check whether `hasPin` in advance")
        }
        let inputController = RequestPinInputViewController(option: pin.option)
        let statusController = PinLockdownViewController(style: .settings)
        super.init(manager: manager, inputController: inputController, statusController: statusController)
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styles.Colors.secondaryBackground
    }
}
