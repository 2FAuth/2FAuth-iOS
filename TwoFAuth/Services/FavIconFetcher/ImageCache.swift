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

// Based on https://github.com/SDWebImage/SDWebImage/blob/master/SDWebImage/Core/SDImageCache.m

import UIKit

final class ImageCache {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: AppDomain + ".imagecache.queue", qos: .userInitiated)
    private let fileManager: FileManager
    private let diskCacheURL: URL

    init() {
        let name = AppDomain + ".imagecache"
        memoryCache.name = name

        fileManager = FileManager()

        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            preconditionFailure("Caches directory doesn't exist")
        }
        diskCacheURL = cachesDirectory.appendingPathComponent(name)
    }

    func image(for key: String, useDiskCache: Bool = true, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = key.sha256

        if let image = memoryCache.object(forKey: cacheKey as NSString) {
            completion(image)
        }
        else if useDiskCache {
            ioQueue.async {
                if !self.fileManager.fileExists(atPath: self.diskCacheURL.path) {
                    try? self.fileManager.createDirectory(at: self.diskCacheURL,
                                                          withIntermediateDirectories: true)
                }

                let url = self.cachePath(for: cacheKey)
                if let data = try? Data(contentsOf: url), let image = UIImage.image(with: data) {
                    self.memoryCache.setObject(image, forKey: cacheKey as NSString)

                    DispatchQueue.main.async {
                        completion(image)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
        else {
            completion(nil)
        }
    }

    func storeImage(_ image: UIImage, useDiskCache: Bool = true, for key: String) {
        let cacheKey = key.sha256

        memoryCache.setObject(image, forKey: cacheKey as NSString)

        if useDiskCache {
            ioQueue.async {
                guard let data = image.imageData() else {
                    return
                }

                let url = self.cachePath(for: cacheKey)
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    private func cachePath(for key: String) -> URL {
        return diskCacheURL.appendingPathComponent(key)
    }
}

// MARK: - FileManager Extension

private extension FileManager {
    func getOrCreateFolderInCaches(folderName: String) -> URL? {
        if let cachesDirectory = urls(for: .cachesDirectory, in: .userDomainMask).first {
            let folderURL = cachesDirectory.appendingPathComponent(folderName)
            if !fileExists(atPath: folderURL.path) {
                do {
                    try createDirectory(atPath: folderURL.path,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
                }
                catch {
                    return nil
                }
            }
            return folderURL
        }
        return nil
    }
}

// MARK: - UIImage Extension

private extension UIImage {
    func imageData() -> Data? {
        guard let alphaInfo = cgImage?.alphaInfo else {
            return nil
        }

        let hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
        if hasAlpha {
            return pngData()
        }
        else {
            return jpegData(compressionQuality: 1.0)
        }
    }

    class func image(with data: Data) -> UIImage? {
        var result = UIImage(data: data)

        if let image = result, let cgImage = image.cgImage, image.imageOrientation != .up {
            let orientation = imageOrientationFromImageData(imageData: data)
            result = UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
        }

        return result
    }

    static func imageOrientationFromImageData(imageData: Data) -> UIImage.Orientation {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: AnyObject],
            let exifOrientation = properties[kCGImagePropertyOrientation as String] as? Int else {
            return .up
        }

        return exifOrientationToiOSOrientation(exifOrientation)
    }

    static func exifOrientationToiOSOrientation(_ exifOrientation: Int) -> UIImage.Orientation {
        switch exifOrientation {
        case 1: return .up
        case 3: return .down
        case 8: return .left
        case 6: return .right
        case 2: return .upMirrored
        case 4: return .downMirrored
        case 5: return .leftMirrored
        case 7: return .rightMirrored
        default: return .up
        }
    }
}
