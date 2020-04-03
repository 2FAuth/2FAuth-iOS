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

protocol OneTimePasswordCellDelegate: AnyObject {
    func oneTimePasswordCellNextPasswordAction(_ cell: OneTimePasswordCell)
}

final class OneTimePasswordCell: UITableViewCell {
    weak var favIconFetcher: FavIconFetcher?
    weak var delegate: OneTimePasswordCellDelegate?

    var oneTimePassword: OneTimePassword? {
        didSet {
            updateCell(with: oneTimePassword)
        }
    }

    var progressModel: ProgressModel? {
        didSet {
            updateProgressModel(progressModel)
        }
    }

    private let parentView = SmoothingCornersView()
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let titleLabel = UILabel()
    private let codeLabel = UILabel()
    private let iconImageView = UIImageView()
    private let nextPasswordButton = UIButton(type: .system)

    private var fetchIconOperation: FavIconCancellationToken?

    private var cellHeight: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        accessibilityTraits.insert(.button)
        isAccessibilityElement = true

        parentView.backgroundColor = Styles.Colors.background
        parentView.cornerRadius = Styles.Sizes.cornerRadius
        contentView.addSubview(parentView)

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.backgroundColor = Styles.Colors.tertiaryBackground
        parentView.addSubview(backgroundImageView)

        overlayView.backgroundColor = overlayViewColor()
        parentView.addSubview(overlayView)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = .clear
        parentView.addSubview(iconImageView)

        codeLabel.textColor = Styles.Colors.otpCode
        codeLabel.numberOfLines = 0
        codeLabel.configureShadow()
        parentView.addSubview(codeLabel)

        titleLabel.textColor = Styles.Colors.label
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.configureShadow()
        parentView.addSubview(titleLabel)

        nextPasswordButton.tintColor = Styles.Colors.tint
        nextPasswordButton.setImage(Styles.Images.refreshIcon, for: .normal)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(contentSizeCategoryDidChangeNotification),
                                       name: UIContentSizeCategory.didChangeNotification,
                                       object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        setNeedsLayout()
        layoutIfNeeded()
        return CGSize(width: size.width, height: min(cellHeight, size.height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margins = deviceSpecificMargins
        parentView.frame = contentView.bounds.inset(by: margins)

        backgroundImageView.frame = parentView.bounds
        overlayView.frame = parentView.bounds

        let labelWidth: CGFloat
        if nextPasswordButton.isHidden {
            labelWidth = parentView.bounds.width - Styles.Sizes.largePadding * 3 - Styles.Sizes.iconSize.width
        }
        else {
            labelWidth = parentView.bounds.width - Styles.Sizes.largePadding * 2 - Styles.Sizes.iconSize.width -
                Styles.Sizes.buttonMinSize - Styles.Sizes.mediumPadding
        }
        let maxLabelSize = CGSize(width: labelWidth, height: Styles.Sizes.uiElementMaxHeight)

        let codeLabelHeight = ceil(codeLabel.sizeThatFits(maxLabelSize).height)
        let titleLabelHeight = ceil(titleLabel.sizeThatFits(maxLabelSize).height)

        var x: CGFloat = Styles.Sizes.largePadding
        var y: CGFloat = Styles.Sizes.mediumPadding
        let iconSize = Styles.Sizes.iconSize
        // icon centered with code label
        iconImageView.frame = CGRect(x: x,
                                     y: y + (codeLabelHeight - iconSize.height) / 2,
                                     width: iconSize.width,
                                     height: iconSize.height)
        x += iconSize.width + Styles.Sizes.largePadding

        codeLabel.frame = CGRect(x: x, y: y, width: labelWidth, height: codeLabelHeight)
        y += codeLabelHeight + Styles.Sizes.smallPadding

        titleLabel.frame = CGRect(x: x, y: y, width: labelWidth, height: titleLabelHeight)
        y += titleLabelHeight + Styles.Sizes.mediumPadding

        if !nextPasswordButton.isHidden {
            x += labelWidth + Styles.Sizes.mediumPadding
            nextPasswordButton.frame = CGRect(x: x,
                                              y: (parentView.bounds.height - Styles.Sizes.buttonMinSize) / 2,
                                              width: Styles.Sizes.buttonMinSize,
                                              height: Styles.Sizes.buttonMinSize)
        }
        else {
            nextPasswordButton.frame = .zero
        }

        cellHeight = margins.top + y + margins.bottom
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        let duration: TimeInterval = isHighlighted ? 0.05 : Styles.Animations.defaultDuration
        let delay: TimeInterval = isHighlighted ? 0 : 0.1
        let options: UIView.AnimationOptions = isHighlighted ? .curveEaseIn : .curveEaseOut
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.overlayView.alpha = self.isHighlighted ? 0.6 : 1.0
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            codeLabel.configureShadow()
            titleLabel.configureShadow()
            overlayView.backgroundColor = overlayViewColor()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        reset()
    }

    // MARK: Private

    private func reset() {
        fetchIconOperation?.cancel()
        fetchIconOperation = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(animateCodeLabelToRed), object: nil)

        backgroundImageView.image = nil
        iconImageView.image = nil
        titleLabel.text = nil
        codeLabel.text = nil
        nextPasswordButton.isHidden = true
    }

    private func updateCell(with oneTimePassword: OneTimePassword?) {
        reset()

        guard let oneTimePassword = oneTimePassword else { return }

        let placeholder = Styles.Images.issuerPlaceholder
        iconImageView.image = placeholder

        let issuer = oneTimePassword.issuer
        fetchIconOperation = favIconFetcher?.favicon(
            for: issuer,
            iconCompletion: { [weak self] image in
                if let image = image {
                    self?.iconImageView.image = image
                }
            },
            blurredIconCompletion: { [weak self] blurredImage in
                self?.backgroundImageView.image = blurredImage
            }
        )

        nextPasswordButton.isHidden = !oneTimePassword.canManualRefresh
        codeLabel.text = oneTimePassword.code

        updateLabels()
        setNeedsLayout()
    }

    private func updateProgressModel(_ progressModel: ProgressModel?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(animateCodeLabelToRed), object: nil)

        codeLabel.textColor = Styles.Colors.otpCode

        #if SCREENSHOT && !APP_EXTENSION
            if CommandLine.isDemoMode {
                return
            }
        #endif /* SCREENSHOT */

        guard let progressModel = progressModel else { return }

        let now = Date()
        let duration = progressModel.duration
        let durationQuater = duration / 4
        let delay = progressModel.endTime.timeIntervalSince1970 - durationQuater - now.timeIntervalSince1970
        if delay <= 0 {
            codeLabel.textColor = Styles.Colors.red
        }
        else {
            perform(#selector(animateCodeLabelToRed), with: nil, afterDelay: delay)
        }
    }

    private func updateLabels() {
        codeLabel.font = Styles.Fonts.otpCode()
        titleLabel.attributedText = oneTimePassword?.formattedTitle
    }

    @objc
    private func contentSizeCategoryDidChangeNotification() {
        updateLabels()
        setNeedsLayout()
    }

    private func overlayViewColor() -> UIColor {
        if #available(iOS 13.0, *) {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            if isDarkMode {
                return UIColor(white: 0.1, alpha: 0.75)
            }
            else {
                return UIColor(white: 1.0, alpha: 0.75)
            }
        }
        else {
            return UIColor(white: 1.0, alpha: 0.75)
        }
    }

    @objc
    private func animateCodeLabelToRed() {
        UIView.transition(with: codeLabel,
                          duration: Styles.Animations.progressColorAnimationDuration,
                          options: .transitionCrossDissolve,
                          animations: {
                              self.codeLabel.textColor = Styles.Colors.red
                          },
                          completion: nil)
    }
}

private extension UILabel {
    func configureShadow() {
        layer.shadowColor = Styles.Colors.shadow.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 2
    }
}
