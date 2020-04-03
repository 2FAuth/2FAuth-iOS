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

func cleanupWorkingDirectory(at url: URL) {
    let path = url.path
    let contents = try! fileManager.contentsOfDirectory(atPath: path)
    for file in contents {
        // Don't remove existing images
        if file == iconsDirName {
            continue
        }

        let fileURL = url.appendingPathComponent(file)
        try! fileManager.removeItem(at: fileURL)
    }

    try! fileManager.createDirectory(at: newIconsDirURL, withIntermediateDirectories: true, attributes: nil)
}
