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

protocol HorizontalAnchors: AnyObject {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
}

protocol VerticalAnchors: AnyObject {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: HorizontalAnchors, VerticalAnchors {}
extension UILayoutGuide: HorizontalAnchors, VerticalAnchors {}

extension UIView {
    func pin(horizontally horizontalAnchors: HorizontalAnchors, left: CGFloat = 0, right: CGFloat = 0) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: horizontalAnchors.leadingAnchor, constant: left),
            horizontalAnchors.trailingAnchor.constraint(equalTo: trailingAnchor, constant: right),
        ])
    }

    func pin(vertically verticalAnchors: VerticalAnchors, top: CGFloat = 0, bottom: CGFloat = 0) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: verticalAnchors.topAnchor, constant: top),
            verticalAnchors.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottom),
        ])
    }

    func pin(edges anchors: HorizontalAnchors & VerticalAnchors, insets: UIEdgeInsets = .zero) {
        pin(horizontally: anchors, left: insets.left, right: insets.right)
        pin(vertically: anchors, top: insets.top, bottom: insets.bottom)
    }
}
