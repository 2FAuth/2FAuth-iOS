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
import Foundation

enum IconSelectionStrategy {
    /// Prefers square (or "almost" square) icons which are >= preferredImageSize,
    /// falls back to the largest square possible or just the largest available icon.
    case smart
    /// Tries to select icons which size is close as possible to preferredImageSize,
    /// but prefers icons with higher resolution over the distance between sizes.
    case greedy
}

// Allowed distance between width and height of the image to consider it square
private let allowedDelta: CGFloat = CGFloat(preferredImageSize) * 0.3

private let selectedIconsPath: String = {
    let path = (newIconsDirFullPath as NSString).appendingPathComponent("_selected")
    try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    return path
}()

func postprocess(strategy: IconSelectionStrategy) {
    convertAllToPngAndSelectPreferredIcons(strategy: strategy)
    resizeToPreferredSizeAndCompressAndMove()
}

private func convertAllToPngAndSelectPreferredIcons(strategy: IconSelectionStrategy) {
    let iconDirectories: [String]
    do {
        iconDirectories = try fileManager.contentsOfDirectory(atPath: newIconsDirFullPath)
    }
    catch {
        fatalError("Failed to get contents of new icons dir: \(String(describing: error))")
    }

    print(">>> Converting all non-png icons to png...")
    for iconDirectory in iconDirectories {
        let iconDirectoryPath = (newIconsDirFullPath as NSString).appendingPathComponent(iconDirectory)
        convertIcons(in: iconDirectoryPath)
    }

    print(">>> Selecting preferred icons...")
    for iconDirectory in iconDirectories {
        let iconDirectoryPath = (newIconsDirFullPath as NSString).appendingPathComponent(iconDirectory)

        let destinationFilename = (iconDirectory as NSString).appendingPathExtension("png")!
        let destinationPath = (selectedIconsPath as NSString).appendingPathComponent(destinationFilename)
        selectIcon(in: iconDirectoryPath, moveToDestinationFilePath: destinationPath, strategy: strategy)
    }
}

private func convertIcons(in directoryPath: String) {
    do {
        let filesToConvert = try fileManager.contentsOfDirectory(atPath: directoryPath).filter { $0.hasSuffix("png") == false }

        for fileName in filesToConvert {
            let inFilePath = (directoryPath as NSString).appendingPathComponent(fileName)
            let outFileName = (UUID().uuidString.sha256 as NSString).appendingPathExtension("png")!
            let outFilePath = (directoryPath as NSString).appendingPathComponent(outFileName)

            shell("/usr/local/bin/convert", inFilePath, outFilePath)

            try fileManager.removeItem(atPath: inFilePath)
        }
    }
    catch {
        print(">>> Converting directory \(directoryPath) to png failed: \(String(describing: error))")
    }
}

private func selectIcon(in directoryPath: String, moveToDestinationFilePath: String, strategy: IconSelectionStrategy) {
    do {
        let imageFiles = try fileManager.contentsOfDirectory(atPath: directoryPath)

        var icons = [WebsiteIcon]()
        for fileName in imageFiles {
            let filePath = (directoryPath as NSString).appendingPathComponent(fileName)

            if let image = NSImage(contentsOfFile: filePath) {
                let icon = WebsiteIcon(filePath: filePath, imageSize: image.size)
                icons.append(icon)
            }
        }

        let preferredIcon: WebsiteIcon?
        switch strategy {
        case .smart:
            preferredIcon = smartPreferredIcon(icons: icons)
        case .greedy:
            preferredIcon = greedyPreferredIcon(icons: icons)
        }

        if let preferredIcon = preferredIcon {
            try fileManager.moveItem(atPath: preferredIcon.filePath, toPath: moveToDestinationFilePath)
        }
        else {
            let dirName = (directoryPath as NSString).lastPathComponent
            print(">>> None of \(icons.count) icons from \(imageFiles.count) files are eligible: \(dirName)")
        }
    }
    catch {
        print(">>> Selecting icons in directory \(directoryPath) failed: \(String(describing: error))")
    }
}

private func sortIconsBySize(_ icons: [WebsiteIcon]) -> [WebsiteIcon] {
    guard !icons.isEmpty else { return [] }

    let iconsInPreferredOrder = icons.sorted { left, right in
        let widthLeft = left.imageSize.width
        let heightLeft = left.imageSize.height
        let widthRight = right.imageSize.width
        let heightRight = right.imageSize.height

        return widthLeft * heightLeft < widthRight * heightRight
    }

    return iconsInPreferredOrder
}

private func sortIcons(_ icons: [WebsiteIcon], preferredSize: CGFloat) -> [WebsiteIcon] {
    guard !icons.isEmpty else { return [] }

    let iconsInPreferredOrder = icons.sorted { left, right in
        let widthLeft = left.imageSize.width
        let heightLeft = left.imageSize.height
        let widthRight = right.imageSize.width
        let heightRight = right.imageSize.height

        let deltaA = abs(widthLeft - preferredSize) * abs(heightLeft - preferredSize)
        let deltaB = abs(widthRight - preferredSize) * abs(heightRight - preferredSize)

        return deltaA < deltaB
    }

    return iconsInPreferredOrder
}

private func greedyPreferredIcon(icons: [WebsiteIcon]) -> WebsiteIcon? {
    let sortedIcons = sortIcons(icons, preferredSize: CGFloat(preferredImageSize))
    var preferredIcon: WebsiteIcon?
    for icon in sortedIcons {
        let width = icon.imageSize.width
        let height = icon.imageSize.height

        let delta = abs(width - height)

        if delta < allowedDelta {
            if width >= CGFloat(preferredImageSize) {
                preferredIcon = icon
                break
            }
        }
    }

    if preferredIcon == nil {
        preferredIcon = sortedIcons.first
    }

    return preferredIcon
}

private func smartPreferredIcon(icons: [WebsiteIcon]) -> WebsiteIcon? {
    let sortedIcons = sortIconsBySize(icons)
    var maxSize = CGSize.zero
    var maxSizedSquareIcon: WebsiteIcon?
    var preferredIcon: WebsiteIcon?
    for icon in sortedIcons {
        let width = icon.imageSize.width
        let height = icon.imageSize.height

        let delta = abs(width - height)

        if delta < allowedDelta {
            if preferredIcon == nil && width >= CGFloat(preferredImageSize) {
                preferredIcon = icon
            }

            if maxSize.width < width {
                maxSizedSquareIcon = icon
                maxSize = icon.imageSize
            }
        }
    }

    if preferredIcon == nil {
        if maxSizedSquareIcon != nil {
            preferredIcon = maxSizedSquareIcon
        }
        else {
            preferredIcon = sortedIcons.last
        }
    }

    return preferredIcon
}

private func resizeToPreferredSizeAndCompressAndMove() {
    print(">>> Resizing png's to preferred size...")

    do {
        let images = try fileManager.contentsOfDirectory(atPath: selectedIconsPath)
        for fileName in images {
            let fullFilePath = (selectedIconsPath as NSString).appendingPathComponent(fileName)
            let resizeParam = "\(preferredImageSize)x\(preferredImageSize)>"

            shell("/usr/local/bin/mogrify", "-resize", resizeParam, fullFilePath)

            // make image circle and save
            let image = NSImage(contentsOfFile: fullFilePath)!
            let rounded = image.roundCorners(radius: image.size.width)
            let result = rounded.pngWrite(to: URL(fileURLWithPath: fullFilePath))
            assert(result)

            shell("/usr/local/bin/pngquant", fullFilePath, "--force", "--ext", ".png")

            let persistentPath = (iconsDirFullPath as NSString).appendingPathComponent(fileName)
            try fileManager.moveItem(atPath: fullFilePath, toPath: persistentPath)
        }
    }
    catch {
        print(">>> Resizing png failed: \(String(describing: error))")
    }
}

@discardableResult
private func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
