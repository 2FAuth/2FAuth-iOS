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

class ScannerViewController<T: QRCodeProcessor, U: QRCodeProcessorResultHandler>: UIViewController where
    T.ProcessingResult == U.Processor.ProcessingResult {
    weak var resultHandler: U? {
        get { cameraController.resultHandler }
        set { cameraController.resultHandler = newValue }
    }

    private var cameraController: CameraViewController<T, U>

    private var showsCancelButtonInNavigationBar: Bool {
        DeviceType.current == .phoneSmall || DeviceType.current == .phoneMedium
    }

    init(otpProcessor: T) {
        cameraController = CameraViewController(metadataObjectProcessor: otpProcessor)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(navigationController != nil, "Should be shown within UINavigationController")

        if showsCancelButtonInNavigationBar {
            let button = UIBarButtonItem(barButtonSystemItem: .cancel,
                                         target: self,
                                         action: #selector(cancelButtonAction))
            button.accessibilityIdentifier = "scanner.cancel"
            navigationItem.leftBarButtonItem = button
        }

        let scannerView = ScannerView(showsCancelButton: !showsCancelButtonInNavigationBar)
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        scannerView.delegate = self
        view.addSubview(scannerView)
        scannerView.pin(edges: view.layoutMarginsGuide)

        embedChild(cameraController, in: scannerView.cameraContentView)

        #if SCREENSHOT
            if CommandLine.isDemoMode {
                if let placeholderPath = UserDefaults.standard.string(forKey: "demo-scanner-placeholder") {
                    let image = UIImage(contentsOfFile: placeholderPath)
                    let imageView = UIImageView(image: image)
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    imageView.contentMode = .scaleAspectFill
                    scannerView.cameraContentView.addSubview(imageView)
                    imageView.pin(edges: scannerView.cameraContentView)
                }
            }
        #endif /* SCREENSHOT */
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        cameraController.resumeQRCodeScanning()
    }

    // MARK: Public

    @objc
    func cancelButtonAction() {
        preconditionFailure("This method must be overridden")
    }
}

extension ScannerViewController: ScannerViewDelegate {
    func scannerViewDidCancel(_ view: ScannerView) {
        cancelButtonAction()
    }
}
