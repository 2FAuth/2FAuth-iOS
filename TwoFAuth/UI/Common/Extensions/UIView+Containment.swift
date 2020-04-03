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

// https://github.com/davedelong/MVCTodo/blob/master/MVCTodo/Extensions/UIView.swift

import UIKit

extension UIView {
    func embedSubview(_ subview: UIView, withinLayoutMargins: Bool = false) {
        // do nothing if this view is already in the right place
        if subview.superview == self { return }

        if subview.superview != nil {
            subview.removeFromSuperview()
        }

        subview.translatesAutoresizingMaskIntoConstraints = false

        subview.frame = bounds
        addSubview(subview)

        let constraints: [NSLayoutConstraint]
        if withinLayoutMargins {
            let guide = layoutMarginsGuide
            constraints = [
                subview.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                guide.trailingAnchor.constraint(equalTo: subview.trailingAnchor),

                subview.topAnchor.constraint(equalTo: guide.topAnchor),
                guide.bottomAnchor.constraint(equalTo: subview.bottomAnchor),
            ]
        }
        else {
            constraints = [
                subview.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: subview.trailingAnchor),

                subview.topAnchor.constraint(equalTo: topAnchor),
                bottomAnchor.constraint(equalTo: subview.bottomAnchor),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }

    func isContainedWithin(_ other: UIView) -> Bool {
        var current: UIView? = self
        while let proposedView = current {
            if proposedView == other { return true }
            current = proposedView.superview
        }
        return false
    }

    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}
