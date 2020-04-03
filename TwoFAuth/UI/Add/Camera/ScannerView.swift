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

protocol ScannerViewDelegate: AnyObject {
    func scannerViewDidCancel(_ view: ScannerView)
}

final class ScannerView: UIView {
    let cameraContentView: UIView = {
        let view = SmoothingCornersView()
        view.backgroundColor = .black // always black
        view.cornerRadius = Styles.Sizes.largeCornerRadius
        return view
    }()

    weak var delegate: ScannerViewDelegate?

    private let showsCancelButton: Bool

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = Styles.Colors.lightText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = LocalizedStrings.scanQRCode
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = DynamicTypeButton(type: .system)
        button.tintColor = Styles.Colors.lightText
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.setTitle(LocalizedStrings.cancel, for: .normal)
        button.accessibilityIdentifier = "scanner.cancel"
        return button
    }()

    init(showsCancelButton: Bool) {
        self.showsCancelButton = showsCancelButton

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(cameraContentView)
        addSubview(titleLabel)

        if showsCancelButton {
            addSubview(cancelButton)
            cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(setNeedsLayout),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = bounds.size

        var titleSize = titleLabel.sizeThatFits(size)
        var buttonSize: CGSize
        if showsCancelButton {
            buttonSize = cancelButton.sizeThatFits(size)
            if buttonSize.height < Styles.Sizes.buttonMinSize {
                buttonSize.height = Styles.Sizes.buttonMinSize
            }
        }
        else {
            buttonSize = .zero
        }
        let titleCameraSpacing = Styles.Sizes.largePadding

        let titleMaxHeight = ceil(size.height * 0.25) // 25% of height
        if titleSize.height > titleMaxHeight {
            titleSize.height = titleMaxHeight
        }

        let buttonMaxHeight = ceil(size.height * 0.12) // 12% of height
        if buttonSize.height > buttonMaxHeight {
            buttonSize.height = buttonMaxHeight
        }

        // fit camera view into possible leftover space with 3/4 aspect ratio
        let maxCameraHeight = size.height - titleSize.height - titleCameraSpacing - buttonSize.height
        let cameraHeight = min(ceil(size.width * 4.0 / 3.0), maxCameraHeight)

        var y = ceil((size.height - titleSize.height - cameraHeight - titleCameraSpacing - buttonSize.height) / 2)

        titleLabel.frame = CGRect(x: 0, y: y, width: size.width, height: titleSize.height)
        y += titleSize.height + titleCameraSpacing

        let cameraWidth = ceil(cameraHeight * 3.0 / 4.0)
        cameraContentView.frame = CGRect(x: ceil((size.width - cameraWidth) / 2),
                                         y: y,
                                         width: cameraWidth,
                                         height: cameraHeight)
        if showsCancelButton {
            y += cameraHeight

            cancelButton.frame = CGRect(x: ceil((size.width - buttonSize.width) / 2),
                                        y: y,
                                        width: buttonSize.width,
                                        height: buttonSize.height)
        }
    }

    // MARK: Private

    @objc
    private func cancelButtonAction() {
        delegate?.scannerViewDidCancel(self)
    }
}
