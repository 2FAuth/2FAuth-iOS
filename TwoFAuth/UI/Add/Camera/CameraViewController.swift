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

final class CameraViewController<T: QRCodeProcessor, U: QRCodeProcessorResultHandler>: UIViewController where
    T.ProcessingResult == U.Processor.ProcessingResult {
    weak var resultHandler: U?

    private let qrScanner = QRScanner.shared
    private let metadataObjectProcessor: T
    private let resumeDebouncer = Debouncer.forScanningQR()
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private var lastUnsuccessfulQRCode: QRScannerProtocol.QRCode?

    private var cameraView: CameraView {
        view as! CameraView
    }

    init(metadataObjectProcessor: T) {
        self.metadataObjectProcessor = metadataObjectProcessor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let cameraView = CameraView(frame: UIScreen.main.bounds)
        cameraView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraView.delegate = self
        view = cameraView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        qrScanner.delegate = self
        cameraView.qrScanner = qrScanner
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if SCREENSHOT
            if CommandLine.isDemoMode {
                return
            }
        #endif /* SCREENSHOT */

        qrScanner.startPreview { [weak self] result in
            if case let .failure(error) = result {
                self?.cameraView.handleQRScannerError(error)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        qrScanner.stopPreview()
    }

    func resumeQRCodeScanning() {
        feedbackGenerator.prepare()
        qrScanner.resumeQRCodeScanning()
    }
}

extension CameraViewController: QRScannerDelegate {
    func didScanQRCode(_ qrCode: QRCode) {
        if let result = metadataObjectProcessor.process(qrCode: qrCode) {
            cameraView.showQRCode(qrCode, asValid: true)
            feedbackGenerator.notificationOccurred(.success)
            resultHandler?.handle(result: result)
        }
        else {
            cameraView.showQRCode(qrCode, asValid: false)

            var shouldGenerateFeedback = false
            if let lastUnsuccessfulQRCode = lastUnsuccessfulQRCode,
                qrCode.stringValue != lastUnsuccessfulQRCode.stringValue {
                shouldGenerateFeedback = true
            }
            else if lastUnsuccessfulQRCode == nil {
                shouldGenerateFeedback = true
            }

            if shouldGenerateFeedback {
                feedbackGenerator.notificationOccurred(.error)
            }
            lastUnsuccessfulQRCode = qrCode

            resumeDebouncer.action = { [weak self] in
                guard let self = self else { return }
                self.cameraView.hideQRCode()
                self.resumeQRCodeScanning()
            }
        }
    }
}

extension CameraViewController: CameraViewDelegate {
    func cameraViewOpenSettings(_ cameraView: CameraView) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension AVMetadataMachineReadableCodeObject: QRCodeRepresentation {}
