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

import AVFoundation
import UIKit

protocol CameraViewDelegate: AnyObject {
    func cameraViewOpenSettings(_ cameraView: CameraView)
}

final class CameraView: UIView {
    var qrScanner: QRScanner? {
        didSet {
            previewLayer.session = qrScanner?.captureSession
        }
    }

    weak var delegate: CameraViewDelegate?

    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let qrCodeLayer = AnimatableShapeLayer()

    private var scannerErrorLabel: UILabel?
    private var openSettingsButton: UIButton?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .black // always black despite of Styles

        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        qrCodeLayer.lineJoin = .round
        qrCodeLayer.lineWidth = 4.0
        previewLayer.addSublayer(qrCodeLayer)

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
        previewLayer.frame = bounds

        guard let scannerErrorLabel = scannerErrorLabel, let openSettingsButton = openSettingsButton else {
            return
        }

        let padding = Styles.Sizes.mediumPadding
        let size = CGSize(width: bounds.size.width - padding * 2, height: bounds.size.height)
        let labelSize = scannerErrorLabel.sizeThatFits(size)
        let buttonSize = openSettingsButton.sizeThatFits(size)

        // the label is placed in either center of the first size half or at the padding
        let labelY = max(ceil((size.height / 2 - labelSize.height) / 2), padding)
        // the label allowed to grow until the button is surrounded by paddings
        let labelHeight = min(labelSize.height, ceil(size.height - buttonSize.height - padding * 3))
        scannerErrorLabel.frame = CGRect(x: padding, y: labelY, width: size.width, height: labelHeight)

        let buttonSpace = size.height - labelHeight - padding * 3
        // the button is centered in the leftover space or placed in the bottom with padding
        let buttonY = min(padding + labelHeight + ceil((buttonSpace - buttonSize.height) / 2),
                          size.height - buttonSize.height - padding)
        openSettingsButton.frame = CGRect(x: max(ceil((bounds.size.width - buttonSize.width) / 2), padding),
                                          y: buttonY, width: min(buttonSize.width, size.width),
                                          height: buttonSize.height)
    }

    func handleQRScannerError(_ error: QRScannerError) {
        guard scannerErrorLabel == nil && openSettingsButton == nil else {
            return
        }

        let scannerErrorLabel = createScannerErrorLabel()
        addSubview(scannerErrorLabel)
        self.scannerErrorLabel = scannerErrorLabel

        let openSettingsButton = createOpenSettingsButton()
        addSubview(openSettingsButton)
        self.openSettingsButton = openSettingsButton

        switch error {
        case .accessDeniedOrRestricted:
            scannerErrorLabel.text = LocalizedStrings.cameraAccessDeniedDescription
            openSettingsButton.isHidden = false
        case .setupFailed:
            scannerErrorLabel.text = LocalizedStrings.cameraSetupFailedDescription
            openSettingsButton.isHidden = true
        }

        setNeedsLayout()
    }

    func showQRCode(_ qrCode: QRScannerProtocol.QRCode, asValid valid: Bool) {
        guard let transformedObject = previewLayer.transformedMetadataObject(for: qrCode)
            as? AVMetadataMachineReadableCodeObject else { return }

        let path = CGMutablePath()
        if !transformedObject.corners.isEmpty {
            for point in transformedObject.corners {
                if point == transformedObject.corners.first {
                    path.move(to: point)
                }
                path.addLine(to: point)
            }
            path.closeSubpath()
        }

        qrCodeLayer.path = path
        let color = valid ? Styles.Colors.tint : Styles.Colors.red
        qrCodeLayer.strokeColor = color.withAlphaComponent(0.75).cgColor
        qrCodeLayer.fillColor = color.withAlphaComponent(0.5).cgColor
        qrCodeLayer.opacity = 1.0
    }

    func hideQRCode() {
        qrCodeLayer.opacity = 0.0
    }

    // MARK: Private

    @objc
    private func openSettingsButtonAction() {
        delegate?.cameraViewOpenSettings(self)
    }
}

// MARK: Private Factory

private extension CameraView {
    func createScannerErrorLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Styles.Colors.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }

    func createOpenSettingsButton() -> UIButton {
        let button = DynamicTypeButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.tintColor = Styles.Colors.lightText
        button.setTitle(LocalizedStrings.openSettings, for: .normal)
        button.addTarget(self, action: #selector(openSettingsButtonAction), for: .touchUpInside)
        return button
    }
}
