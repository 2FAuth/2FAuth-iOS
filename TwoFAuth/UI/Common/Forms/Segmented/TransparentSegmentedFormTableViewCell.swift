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

final class TransparentSegmentedFormTableViewCell: UITableViewCell, SegmentedFormTableViewCell {
    var model: SegmentedFormCellModel? {
        didSet {
            guard let model = model else { return }

            accessibilityIdentifier = model.accessibilityIdentifier

            segmentedControl.removeAllSegments()
            var index = 0
            for item in model.items {
                segmentedControl.insertSegment(withTitle: item.description, at: index, animated: false)
                index += 1
            }

            segmentedControl.selectedSegmentIndex = model.selectedIndex
        }
    }

    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            segmentedControl.backgroundColor = Styles.Colors.segmentedControlBackground
            segmentedControl.selectedSegmentTintColor = Styles.Colors.selectedSegmentTint

            segmentedControl.setTitleTextAttributes([.foregroundColor: Styles.Colors.lightText], for: .normal)
            segmentedControl.setTitleTextAttributes([.foregroundColor: Styles.Colors.lightText], for: .selected)
        }
        else {
            segmentedControl.tintColor = Styles.Colors.secondaryTint
        }
        segmentedControl.addTarget(self, action: #selector(segmentedControlAction), for: .valueChanged)
        return segmentedControl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = backgroundColor

        contentView.addSubview(segmentedControl)

        let guide = contentView.layoutMarginsGuide
        segmentedControl.pin(edges: guide)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func segmentedControlAction() {
        model?.selectedIndex = segmentedControl.selectedSegmentIndex
    }
}
