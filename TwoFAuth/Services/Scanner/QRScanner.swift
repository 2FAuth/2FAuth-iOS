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
import Foundation
import os.log

protocol QRScannerProtocol: AnyObject {
    typealias QRCode = AVMetadataMachineReadableCodeObject

    var captureSession: AVCaptureSession { get }
    var delegate: QRScannerDelegate? { get set }

    func startPreview(completion: @escaping (Result<Void, QRScannerError>) -> Void)
    func stopPreview()
    func resumeQRCodeScanning()
}

enum QRScannerError: Error {
    case accessDeniedOrRestricted
    case setupFailed
}

protocol QRScannerDelegate: AnyObject {
    typealias QRCode = AVMetadataMachineReadableCodeObject

    func didScanQRCode(_ qrCode: QRCode)
}

final class QRScanner: NSObject, QRScannerProtocol {
    static let shared = QRScanner()

    weak var delegate: QRScannerDelegate?

    var captureSession: AVCaptureSession {
        if _captureSession == nil {
            _captureSession = AVCaptureSession()
        }
        return _captureSession!
    }

    private var _captureSession: AVCaptureSession?

    private var sessionQueue: DispatchQueue {
        if _sessionQueue == nil {
            _sessionQueue = DispatchQueue(label: AppDomain + ".scan.session-queue")
        }
        return _sessionQueue!
    }

    private var _sessionQueue: DispatchQueue?

    private var metadataQueue: DispatchQueue {
        if _metadataQueue == nil {
            _metadataQueue = DispatchQueue(label: AppDomain + ".scan.metadata-queue")
        }
        return _metadataQueue!
    }

    private var _metadataQueue: DispatchQueue?

    private var isCaptureSessionConfigured = false
    private var isQRCodeScanningPaused = true

    private override init() {
        super.init()
    }

    // MARK: Public API

    func startPreview(completion: @escaping (Result<Void, QRScannerError>) -> Void) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(stopPreviewInternal), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tearDown), object: nil)

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.startCaptureSession(completion: completion)
                }
                else {
                    DispatchQueue.main.async {
                        completion(.failure(QRScannerError.accessDeniedOrRestricted))
                    }
                }
            }
        case .authorized:
            startCaptureSession(completion: completion)
        case .denied, .restricted:
            completion(.failure(QRScannerError.accessDeniedOrRestricted))
        @unknown default:
            preconditionFailure("unhandled authorization status")
        }
    }

    func stopPreview() {
        perform(#selector(stopPreviewInternal), with: nil, afterDelay: Self.stopPreviewTimeout)
    }

    func resumeQRCodeScanning() {
        isQRCodeScanningPaused = false
    }

    // MARK: Private

    @objc
    private func stopPreviewInternal() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()

                DispatchQueue.main.async {
                    self.perform(#selector(QRScanner.tearDown), with: nil, afterDelay: Self.sessionKeepAlive)
                }
            }
        }
    }

    @objc
    private func tearDown() {
        _captureSession = nil
        _sessionQueue = nil
        _metadataQueue = nil
        isCaptureSessionConfigured = false
        isQRCodeScanningPaused = true
    }

    private func startCaptureSession(completion: @escaping (Result<Void, QRScannerError>) -> Void) {
        sessionQueue.async {
            do {
                if !self.isCaptureSessionConfigured {
                    try self.setupCaptureSession()
                }
                self.isCaptureSessionConfigured = true

                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }

                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
            catch let error as QRScannerError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
            catch {
                preconditionFailure("\(error) must be converted into QRScannerError")
            }
        }
    }

    private func setupCaptureSession() throws {
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw QRScannerError.setupFailed
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        }
        catch {
            throw QRScannerError.setupFailed
        }

        // allow to fail fine-grained device setup
        do {
            try device.lockForConfiguration()
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
        }
        catch {
            os_log("Failed to lock AVCaptureDevice: '%{public}@'", log: .default, type: .debug, String(describing: error))
        }

        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        else {
            throw QRScannerError.setupFailed
        }

        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: metadataQueue)
            if output.availableMetadataObjectTypes.contains(.qr) {
                output.metadataObjectTypes = [.qr]
            }
            else {
                throw QRScannerError.setupFailed
            }
        }
        else {
            throw QRScannerError.setupFailed
        }
    }

    private func pauseQRCodeScanning() {
        isQRCodeScanningPaused = true
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension QRScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if isQRCodeScanningPaused {
            return
        }

        guard let object = metadataObjects.first(where: { $0.type == .qr }) as? QRCode else {
            return
        }

        pauseQRCodeScanning()

        DispatchQueue.main.async {
            self.delegate?.didScanQRCode(object)
        }
    }
}

// MARK: Private

private extension QRScanner {
    static let stopPreviewTimeout: TimeInterval = 3
    static let sessionKeepAlive: TimeInterval = 5
}
