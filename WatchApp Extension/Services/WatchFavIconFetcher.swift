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

import Foundation

final class WatchFavIconFetcher {
    private let userDefaults: UserDefaults
    private let imageCache = ImageCache()
    private let imageProcessingQueue = DispatchQueue(label: AppDomain + ".watch.faviconfetcher.queue", qos: .userInitiated)
    private static let iconsFolder = "WebsiteIcons"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func fetchIcon(for issuer: String, iconCompletion: @escaping (UIImage?) -> Void) {
        assert(Thread.isMainThread)

        guard let iconName = userDefaults.favIconsByIssuer[issuer] else {
            iconCompletion(nil)

            return
        }

        imageProcessingQueue.async {
            let iconFolderURL = Bundle.appBundle.bundleURL.appendingPathComponent(Self.iconsFolder)
            let iconURL = iconFolderURL.appendingPathComponent(iconName)
            guard let image = UIImage(contentsOfFile: iconURL.path) else {
                DispatchQueue.main.async {
                    iconCompletion(nil)
                }

                return
            }

            DispatchQueue.main.async {
                self.imageCache.storeImage(image, useDiskCache: false, for: issuer)

                iconCompletion(image)
            }
        }
    }
}
