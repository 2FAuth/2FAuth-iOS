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

import AppKit
import FavIcon
import Foundation

func downloadIcons(for categories: [WebsiteCategory], completion: @escaping () -> Void) {
    let dispatchGroup = DispatchGroup()

    for category in categories {
        for website in category.websites {
            let fileName = website.iconFileFullName
            let fullPath = (iconsDirFullPath as NSString).appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fullPath) {
                continue
            }

            dispatchGroup.enter()

            downloadIcons(for: website, category: category) {
                dispatchGroup.leave()
            }
        }
    }

    dispatchGroup.notify(queue: DispatchQueue.main) {
        completion()
    }
}

private func downloadIcons(for website: Website, category: WebsiteCategory, completion: @escaping () -> Void) {
    let websiteIconsDirURL = newIconsDirURL.appendingPathComponent(website.iconFilename)
    try? fileManager.createDirectory(at: websiteIconsDirURL, withIntermediateDirectories: true, attributes: nil)

    FavIcon.scan(URL(string: website.url)!) { icons in
        guard !icons.isEmpty else {
            if let img = website.img {
                print(">>> Icons for \(website.url) not found, trying to download fallback icon")

                let urlString = "https://github.com/2factorauth/twofactorauth/raw/master/img/\(category.name!)/\(img)"
                let url = URL(string: urlString)!
                download(url: url, targetDirURL: websiteIconsDirURL, completion: completion)
            }
            else {
                print(">>> Icons for \(website.url) not found and there is no fallback icon")

                completion()
            }

            return
        }

        let dispatchGroup = DispatchGroup()
        for icon in icons {
            dispatchGroup.enter()

            download(url: icon.url, targetDirURL: websiteIconsDirURL) {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
}

private func download(url: URL, targetDirURL: URL, completion: @escaping () -> Void) {
    URLSession.shared.downloadTask(with: url) { fileURL, _, error in
        guard error == nil else {
            let nsError = error! as NSError
            print(">>> Network error for \(url): \(nsError.code) (\(nsError.localizedDescription))")
            completion()
            return
        }

        guard let fileURL = fileURL else {
            fatalError("No file for \(url)")
        }

        let minValidFileSize = 10 // 10 Bytes, for no reason
        guard getSizeOfFile(fileURL: fileURL) > minValidFileSize else {
            completion()
            return
        }

        // assume, all unknown images are png
        // for now, that's actually true and this can be fixed later
        let ext = url.pathExtension.isEmpty ? "png" : url.pathExtension
        let filename = (UUID().uuidString.sha256 as NSString).appendingPathExtension(ext)!
        let toURL = targetDirURL.appendingPathComponent(filename)

        do {
            try fileManager.moveItem(at: fileURL, to: toURL)
        }
        catch {
            print(">>> Move downloaded icon for \(url) error \(error)")
        }

        completion()
    }.resume()
}

private func getSizeOfFile(fileURL: URL) -> UInt64 {
    do {
        let dict = try fileManager.attributesOfItem(atPath: fileURL.path)
        let fileSize = dict[FileAttributeKey.size] as! NSNumber
        return fileSize.uint64Value
    }
    catch {
        return 0
    }
}
