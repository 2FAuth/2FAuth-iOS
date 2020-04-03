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

final class TransparentSelectorFormTableViewCell: UITableViewCell, SelectorFormTableViewCell {
    var model: SelectorFormCellModel? {
        didSet {
            accessibilityIdentifier = model?.accessibilityIdentifier

            assert((model?.detail) == nil,
                   "TransparentSelectorFormTableViewCell doesn't support displaying detail")
            textLabel?.text = model?.title
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = backgroundColor

        textLabel?.textColor = Styles.Colors.lightText
        textLabel?.font = .preferredFont(forTextStyle: .headline)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        if model?.isEnabled ?? false {
            UIView.animate(withDuration: 0.5) {
                self.textLabel?.alpha = highlighted ? 0.5 : 1.0
            }
        }
    }
}
