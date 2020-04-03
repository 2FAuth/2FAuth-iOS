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

final class PinCodeKeyboardView: UIView {
    weak var textInput: UITextInput?

    private let buttons = Array(generating: PinCodeKeyboardButton(), count: 10)
    private let buttonSize = CGSize(width: 75, height: 75)
    private let rowsCount = 4
    private let sectionsCount = 3
    private let horizontalSpacing: CGFloat = 28
    private let verticalSpacing: CGFloat = 15

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var left: CGFloat = 0
        var top: CGFloat = 0
        for button in buttons {
            let x = button.value == 0 ? (bounds.width - buttonSize.width) / 2 : left
            button.frame = CGRect(x: x, y: top, width: buttonSize.width, height: buttonSize.height)
            if button.value % sectionsCount == 0 {
                left = 0
                top += buttonSize.height + verticalSpacing
            }
            else {
                left += buttonSize.width + horizontalSpacing
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: buttonSize.width * CGFloat(sectionsCount) + horizontalSpacing * CGFloat(sectionsCount - 1),
               height: buttonSize.height * CGFloat(rowsCount) + verticalSpacing * CGFloat(rowsCount - 1))
    }

    // MARK: Private

    private func setup() {
        let values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
        let subtitles = [" ", "A B C", "D E F", "G H I", "J K L", "M N O", "P Q R S", "T U V", "W X Y Z", nil]
        assert(buttons.count == values.count && buttons.count == subtitles.count)
        for (index, button) in buttons.enumerated() {
            button.value = values[index]
            button.subtitle = subtitles[index]
            button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
            addSubview(button)
        }
    }

    @objc
    private func buttonAction(_ sender: PinCodeKeyboardButton) {
        UIDevice.current.playInputClick()
        textInput?.insertText("\(sender.value)")
    }
}
