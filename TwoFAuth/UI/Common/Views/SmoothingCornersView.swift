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

final class SmoothingCornersView: UIView {
    var cornerRadius: CGFloat = 0 {
        didSet {
            updateMaskIfNeeded()
        }
    }

    private let maskLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskIfNeeded()
    }

    // MARK: Private

    private func updateMaskIfNeeded() {
        if cornerRadius > 0 {
            if maskLayer.path == nil || !maskLayer.path!.boundingBox.equalTo(bounds) {
                let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
                maskLayer.path = path.cgPath
                layer.mask = maskLayer
            }
        }
        else {
            maskLayer.path = nil
        }
    }
}
