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

struct GHFileObject: Codable {
    var name: String {
        (_name as NSString).deletingPathExtension
    }

    let url: String
    private let _name: String

    enum CodingKeys: String, CodingKey {
        case _name = "name"
        case url = "download_url"
    }
}

struct Website: Codable {
    let name: String
    let url: String
    let tfa: [String]?
    let img: String?

    // result icon name
    var icon: String?
}

extension Website {
    /// File name **without** extension
    var iconFilename: String {
        url.sha256
    }

    var iconFileFullName: String {
        (iconFilename as NSString).appendingPathExtension("png")!
    }
}

struct WebsiteCategory: Codable {
    var name: String?
    let websites: [Website]
}

struct WebsiteIcon {
    let filePath: String
    let imageSize: CGSize
}
