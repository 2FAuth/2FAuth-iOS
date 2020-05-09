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

import os.log
import UIKit

protocol FavIconCancellationToken: AnyObject {
    func cancel()
}

private final class FavIconOperation: FavIconCancellationToken {
    private(set) var isCancelled = false

    func cancel() {
        assert(Thread.isMainThread)
        isCancelled = true
    }
}

final class FavIconFetcher {
    private let userDefaults: UserDefaults
    private let imageCache = ImageCache()
    private let websiteCatalog = WebsiteCatalog()
    private var notFoundIssuers = Set<String>()
    private let imageProcessingQueue = DispatchQueue(label: AppDomain + ".faviconfetcher.queue", qos: .userInitiated)
    private let log = OSLog(subsystem: AppDomain, category: String(describing: FavIconFetcher.self))
    private static let iconsFolder = "WebsiteIcons"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    @discardableResult
    func favicon(
        for issuer: String,
        iconCompletion: @escaping (UIImage?) -> Void,
        blurredIconCompletion: ((UIImage?) -> Void)? = nil
    ) -> FavIconCancellationToken? {
        assert(Thread.isMainThread)

        if notFoundIssuers.contains(issuer) {
            iconCompletion(nil)
            return nil
        }

        let operation = FavIconOperation()
        imageFromCache(for: issuer,
                       operation: operation,
                       iconCompletion: iconCompletion,
                       blurredIconCompletion: blurredIconCompletion)
        return operation
    }

    // MARK: Private

    private func imageFromCache(for issuer: String,
                                operation: FavIconOperation,
                                iconCompletion: @escaping (UIImage?) -> Void,
                                blurredIconCompletion: ((UIImage?) -> Void)?) {
        imageCache.image(for: issuer, useDiskCache: false) { [weak self] image in
            guard let self = self else { return }
            assert(Thread.isMainThread)

            if operation.isCancelled {
                return
            }

            if let image = image {
                iconCompletion(image)

                guard blurredIconCompletion != nil else { return }

                self.imageCache.image(for: self.blurredImageKey(for: issuer)) { [weak self] blurredImage in
                    guard let self = self else { return }

                    if operation.isCancelled {
                        return
                    }

                    if blurredImage == nil {
                        self.blurImage(image, issuer: issuer,
                                       operation: operation,
                                       blurredIconCompletion: blurredIconCompletion)
                    }
                    else {
                        blurredIconCompletion?(blurredImage)
                    }
                }
            }
            else {
                os_log("Icon for '%@' was NOT found in cache", log: self.log, type: .debug, issuer)

                self.fetchWebsite(for: issuer,
                                  operation: operation,
                                  iconCompletion: iconCompletion,
                                  blurredIconCompletion: blurredIconCompletion)
            }
        }
    }

    private func fetchWebsite(for issuer: String,
                              operation: FavIconOperation,
                              iconCompletion: @escaping (UIImage?) -> Void,
                              blurredIconCompletion: ((UIImage?) -> Void)?) {
        let favIconsByIssuer = userDefaults.favIconsByIssuer
        if let iconName = favIconsByIssuer[issuer] {
            fetchIcon(named: iconName,
                      issuer: issuer,
                      operation: operation,
                      iconCompletion: iconCompletion,
                      blurredIconCompletion: blurredIconCompletion)

            return
        }

        websiteCatalog.fetchWebsiteIconName(for: issuer) { [weak self] iconName in
            guard let self = self else { return }
            assert(Thread.isMainThread)

            if operation.isCancelled {
                return
            }

            if let iconName = iconName {
                var mutableFavIconsByIssuer = favIconsByIssuer
                mutableFavIconsByIssuer[issuer] = iconName
                self.userDefaults.favIconsByIssuer = mutableFavIconsByIssuer

                self.fetchIcon(named: iconName,
                               issuer: issuer,
                               operation: operation,
                               iconCompletion: iconCompletion,
                               blurredIconCompletion: blurredIconCompletion)
            }
            else {
                self.notFoundIssuers.insert(issuer)
                os_log("Website for '%@' was not found", log: self.log, type: .debug, issuer)

                iconCompletion(nil)
                blurredIconCompletion?(nil)
            }
        }
    }

    private func fetchIcon(named iconName: String,
                           issuer: String,
                           operation: FavIconOperation,
                           iconCompletion: @escaping (UIImage?) -> Void,
                           blurredIconCompletion: ((UIImage?) -> Void)?) {
        imageProcessingQueue.async {
            let iconFolderURL = Bundle.appBundle.bundleURL.appendingPathComponent(Self.iconsFolder)
            let iconURL = iconFolderURL.appendingPathComponent(iconName)
            guard let image = UIImage(contentsOfFile: iconURL.path) else {
                DispatchQueue.main.async {
                    if !operation.isCancelled {
                        iconCompletion(nil)
                        blurredIconCompletion?(nil)
                    }
                }

                return
            }

            DispatchQueue.main.async {
                self.imageCache.storeImage(image, useDiskCache: false, for: issuer)

                if !operation.isCancelled {
                    iconCompletion(image)
                }

                self.blurImage(image,
                               issuer: issuer,
                               operation: operation,
                               blurredIconCompletion: blurredIconCompletion)
            }
        }
    }

    private func blurImage(_ image: UIImage,
                           issuer: String,
                           operation: FavIconOperation,
                           blurredIconCompletion: ((UIImage?) -> Void)?) {
        let cornerRadiusPercent: CGFloat = 0.25
        let saturationFactor: CGFloat = 1.8
        imageProcessingQueue.async {
            let radius = ceil(min(image.size.width, image.size.height) * cornerRadiusPercent)
            let blurredImage = TFAImageEffects.imageByApplyingBlur(to: image,
                                                                   withRadius: radius,
                                                                   saturationDeltaFactor: saturationFactor)

            DispatchQueue.main.async {
                if let blurredImage = blurredImage {
                    self.imageCache.storeImage(blurredImage, for: self.blurredImageKey(for: issuer))
                }

                if !operation.isCancelled {
                    blurredIconCompletion?(blurredImage)
                }
            }
        }
    }

    private func blurredImageKey(for issuer: String) -> String {
        issuer + "##blurred"
    }
}
