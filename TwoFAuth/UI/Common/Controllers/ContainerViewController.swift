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

final class ContainerViewController: UIViewController {
    var content: UIViewController? {
        didSet {
            transition(from: oldValue, to: content)
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    init(content: UIViewController?) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(content: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        transition(from: nil, to: content)
    }

    override var childForStatusBarStyle: UIViewController? {
        content
    }
}
