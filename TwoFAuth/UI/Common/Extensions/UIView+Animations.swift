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

extension UIView {
    class func animate(delay: TimeInterval = 0, animations: @escaping () -> Void,
                       completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: Styles.Animations.defaultDuration,
                       delay: delay,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.0,
                       options: [.curveEaseInOut],
                       animations: animations,
                       completion: completion)
    }

    func shakeView() {
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shakeAnimation.duration = 0.5
        shakeAnimation.values = [-24, 24, -16, 16, -8, 8, -4, 4, 0]
        layer.add(shakeAnimation, forKey: "shake-animation")
    }
}
