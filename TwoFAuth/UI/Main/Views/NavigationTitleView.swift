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

final class NavigationTitleView: UIView {
    private let progressView = ProgressView(frame: CGRect(x: 0, y: 0,
                                                          width: Styles.Sizes.progressSize,
                                                          height: Styles.Sizes.progressSize))
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(progressView)

        titleLabel.font = Styles.Fonts.navigationTitle
        titleLabel.textColor = Styles.Colors.label
        titleLabel.text = LocalizedStrings.appName
        addSubview(titleLabel)
        titleLabel.sizeToFit()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let progressSize = Styles.Sizes.progressSize
        return CGSize(width: progressSize + Styles.Sizes.mediumPadding + titleLabel.bounds.width,
                      height: progressSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let x: CGFloat
        let width = titleLabel.bounds.width
        if progressView.isHidden {
            x = ceil((bounds.width - width) / 2)
        }
        else {
            x = Styles.Sizes.progressSize + Styles.Sizes.mediumPadding
        }
        titleLabel.frame = CGRect(x: x, y: 0, width: width, height: bounds.size.height)
    }

    func update(with model: ProgressModel?) {
        progressView.isHidden = model == nil
        progressView.update(with: model)

        setNeedsLayout()
    }
}
