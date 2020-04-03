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

import Foundation

final class Debouncer {
    var action: (() -> Void)? {
        didSet {
            debounce()
        }
    }

    private let delay: Double
    private weak var timer: Timer?

    init(delay: Double) {
        self.delay = delay
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Private

    private func debounce() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: delay,
            target: self,
            selector: #selector(timerAction),
            userInfo: nil,
            repeats: false
        )
    }

    @objc
    private func timerAction() {
        action?()
    }
}

extension Debouncer {
    class func forScanningQR() -> Debouncer {
        Debouncer(delay: 0.3)
    }

    class func forUpdatingIssuerIcon() -> Debouncer {
        Debouncer(delay: 0.2)
    }
}
