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

final class RootWindow: UIWindow {
    private let authManager: AuthenticationManager
    private var blurView: UIVisualEffectView?

    init(frame: CGRect, authManager: AuthenticationManager) {
        self.authManager = authManager
        super.init(frame: frame)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(didEnterBackgroundNotification),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(didBecomeActiveNotification),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    @objc
    private func didEnterBackgroundNotification() {
        let passcode = authManager.passcode
        if !passcode.hasPin {
            return
        }

        // don't add blur if the lock window is shown already
        guard blurView == nil, isKeyWindow else { return }

        let effect = UIBlurEffect(style: Styles.Misc.lockBlurStyle)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
        self.blurView = blurView
    }

    @objc
    private func didBecomeActiveNotification() {
        guard blurView != nil else { return }

        let duration = 0.15
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: {
            self.blurView?.alpha = 0
        })
        animator.addCompletion { _ in
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
        animator.startAnimation()
    }
}
