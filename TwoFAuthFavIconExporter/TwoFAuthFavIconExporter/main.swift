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
import Cocoa
import CoreData
import Foundation

// Pre-requirements:
//
// brew install imagemagick
// brew install pngquant
//

// Configuration
//
// Configure strategy to select among downloaded icons.
// See IconSelectionStrategy enum documentation.
//
// Typical workflow: run `.smart` first, add to git, update with `.greedy` results
// and manually select the best option
//
private let iconSelectionStrategy = IconSelectionStrategy.smart

// MARK: - Globals

// --- GLOBAL VARS BEGIN ---

let fileManager = FileManager.default

let workingURL = NSPersistentContainer.defaultDirectoryURL()

let iconsDirName = "WebsiteIcons"
let iconsDirURL: URL = {
    let url = workingURL.appendingPathComponent(iconsDirName)
    try! fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    return url
}()

let iconsDirFullPath = iconsDirURL.path

let newIconsDirName = "WebsiteIconsNew"
let newIconsDirURL = workingURL.appendingPathComponent(newIconsDirName)
let newIconsDirFullPath = newIconsDirURL.path

let preferredImageSize: Int = 24 * 3 // Styles.Sizes.iconSize * max_display_scale

// --- GLOBAL VARS END ---

// MARK: - Main Routine

private func run() {
    cleanupWorkingDirectory(at: workingURL)

    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    fetch { categories in
        downloadIcons(for: categories) {
            postprocess(strategy: iconSelectionStrategy)

            update(categories: categories) { websites in
                save(websites: websites) {
                    dispatchGroup.leave()
                }
            }
        }
    }

    dispatchGroup.notify(queue: DispatchQueue.main) {
        let path = workingURL.path
        print(">>> All done: \(path)")
        NSWorkspace.shared.openFile(path)

        exit(EXIT_SUCCESS)
    }

    dispatchMain()
}

// MARK: - Run

run()
