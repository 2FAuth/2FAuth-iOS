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

final class InsetsTextField: UITextField {
    let horizontalInset: CGFloat
    let verticalInset: CGFloat

    init(horizontalInset: CGFloat = 0, verticalInset: CGFloat = 0) {
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset

        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: horizontalInset, dy: verticalInset)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: horizontalInset, dy: verticalInset)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: horizontalInset, dy: verticalInset)
    }
}
