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

// Slightly fixed version of
// https://github.com/davedelong/MVCTodo/blob/master/MVCTodo/Extensions/UIViewController.swift

import UIKit

extension UIViewController {
    func embedChild(_ newChild: UIViewController,
                    in container: UIView? = nil,
                    withinLayoutMargins: Bool = false) {
        // if the view controller is already a child of something else, remove it
        if let oldParent = newChild.parent, oldParent != self {
            unembed(newChild)
        }

        // since .view returns an IUO, by default the type of this is "UIView?"
        // explicitly type the variable because We Know Better™
        var targetContainer: UIView = container ?? view
        if targetContainer.isContainedWithin(view) == false {
            targetContainer = view
        }

        // add the view controller as a child
        if newChild.parent != self {
            addChild(newChild)
            targetContainer.embedSubview(newChild.view, withinLayoutMargins: withinLayoutMargins)
            newChild.didMove(toParent: self)
        }
        else {
            // the viewcontroller is already a child
            // make sure it's in the right view

            // we don't do the appearance transition stuff here,
            // because the vc is already a child, so *presumably*
            // that transition stuff has already happened
            targetContainer.embedSubview(newChild.view)
        }
    }

    func unembed(_ child: UIViewController) {
        child.willMove(toParent: nil)
        if child.viewIfLoaded?.superview != nil {
            child.viewIfLoaded?.removeFromSuperview()
        }
        child.removeFromParent()
    }
}
