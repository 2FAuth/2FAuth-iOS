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
    func findConstraint(layoutAttribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        if let constraints = superview?.constraints {
            for constraint in constraints
                where itemsMatch(constraint: constraint, layoutAttribute: layoutAttribute) {
                return constraint
            }
        }

        return nil
    }

    // MARK: Private

    private func itemsMatch(constraint: NSLayoutConstraint,
                            layoutAttribute: NSLayoutConstraint.Attribute) -> Bool {
        if let firstItem = constraint.firstItem as? UIView,
            let secondItem = constraint.secondItem as? UIView {
            let firstItemMatch = firstItem == self && constraint.firstAttribute == layoutAttribute
            let secondItemMatch = secondItem == self && constraint.secondAttribute == layoutAttribute

            return firstItemMatch || secondItemMatch
        }

        return false
    }
}
