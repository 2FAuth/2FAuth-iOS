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

extension UIViewController {
    /// Cross-dissolve transition (if needed)
    func transition(from: UIViewController?,
                    to: UIViewController?,
                    in container: UIView? = nil) {
        let duration: TimeInterval
        let options: UIView.AnimationOptions
        if viewIfLoaded?.window == nil {
            duration = 0
            options = []
        }
        else {
            duration = Styles.Animations.defaultDuration
            options = .transitionCrossDissolve
        }

        let container: UIView = container ?? view
        switch (from, to) {
        case let (old?, new?):
            transition(from: old, to: new, in: container, duration: duration, options: options)
        case (nil, let new?):
            transition(to: new, in: container, duration: duration, options: options)
        case (let old?, nil):
            transition(from: old, in: container, duration: duration, options: options)
        case (nil, nil):
            return
        }
    }

    /// Embed the "to" view, animate it in
    func transition(to: UIViewController,
                    in container: UIView,
                    duration: TimeInterval,
                    options: UIView.AnimationOptions = []) {
        addChild(to)
        to.view.alpha = 0
        container.embedSubview(to.view)

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            to.view.alpha = 1
        }, completion: { _ in
            to.didMove(toParent: self)
        })
    }

    /// Animate out the "from" view, remove it
    func transition(from: UIViewController,
                    in container: UIView,
                    duration: TimeInterval,
                    options: UIView.AnimationOptions = []) {
        from.willMove(toParent: nil)
        UIView.animate(withDuration: duration, animations: {
            from.view.alpha = 0
        }, completion: { _ in
            from.view.removeFromSuperview()
            from.removeFromParent()
        })
    }

    /// Animate from "from" view to "to" view
    func transition(from: UIViewController,
                    to: UIViewController,
                    in container: UIView,
                    duration: TimeInterval,
                    options: UIView.AnimationOptions = []) {
        if from == to { return }

        from.willMove(toParent: nil)
        addChild(to)

        to.view.alpha = 0
        from.view.alpha = 1

        container.embedSubview(to.view)
        container.bringSubviewToFront(from.view)

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            to.view.alpha = 1
            from.view.alpha = 0
        }, completion: { _ in
            from.view.removeFromSuperview()

            from.removeFromParent()
            to.didMove(toParent: self)
        })
    }
}
