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

final class AnimatableShapeLayer: CAShapeLayer {
    override func action(forKey event: String) -> CAAction? {
        if event == "path" {
            return customAction(forKey: event)
        }
        return super.action(forKey: event)
    }

    // MARK: Private

    private func customAction(forKey key: String) -> CAAction {
        let animation = CABasicAnimation(keyPath: key)
        animation.fromValue = presentation()?.value(forKey: key)
        animation.duration = CATransaction.animationDuration()

        return animation
    }
}
