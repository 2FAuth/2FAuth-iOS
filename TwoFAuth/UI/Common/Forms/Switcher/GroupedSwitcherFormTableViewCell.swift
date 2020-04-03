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

final class GroupedSwitcherFormTableViewCell: UITableViewCell, SwitcherFormTableViewCell {
    var model: SwitcherFormCellModel? {
        didSet {
            accessibilityIdentifier = model?.accessibilityIdentifier

            model?.changesObserver = self
            textLabel?.text = model?.title
            switcher.isOn = model?.isOn ?? false

            if let model = model {
                textLabel?.textColor = model.titleStyle == .default ? Styles.Colors.label : Styles.Colors.tint
            }
        }
    }

    private lazy var switcher: UISwitch = {
        let switcher = UISwitch()
        switcher.onTintColor = Styles.Colors.tint
        switcher.addTarget(self, action: #selector(switcherAction), for: .valueChanged)
        switcher.sizeToFit()
        return switcher
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        accessoryView = switcher
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    @objc
    private func switcherAction() {
        guard let model = model else {
            return
        }

        model.isOn = !model.isOn
        model.action?(model, self)
    }
}

extension GroupedSwitcherFormTableViewCell: SwitcherFormCellModelChangesObserver {
    func switcherFormCellModelDidChangeIsOn(_ model: SwitcherFormCellModel) {
        switcher.setOn(model.isOn, animated: true)
    }
}
