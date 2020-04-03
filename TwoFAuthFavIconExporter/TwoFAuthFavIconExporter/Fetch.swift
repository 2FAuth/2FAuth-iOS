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

import CoreData
import Foundation
import Yams

func fetch(completion: @escaping ([WebsiteCategory]) -> Void) {
    fetchTwoFactorAuthData { files in
        fetchWebsiteData(files: files!) { categories in
            guard let categories = categories else {
                fatalError("Failed to fetch data")
            }

            let filtered = filter(categories: categories)
            let result = [manual] + filtered

            completion(result)
        }
    }
}

private func filter(categories: [WebsiteCategory]) -> [WebsiteCategory] {
    let supportedTFA = "totp"

    var filteredCategories = [WebsiteCategory]()
    for category in categories {
        let filteredWebsites = category.websites.filter { $0.tfa?.contains(supportedTFA) ?? false }
        if !filteredWebsites.isEmpty {
            let newCategory = WebsiteCategory(name: category.name, websites: filteredWebsites)
            filteredCategories.append(newCategory)
        }
    }

    return filteredCategories
}

private func fetchTwoFactorAuthData(completion: @escaping ([GHFileObject]?) -> Void) {
    print(">>> Fetching data from github.com/2factorauth/twofactorauth")

    let url = URL(string: "https://api.github.com/repos/2factorauth/twofactorauth/contents/_data")!
    URLSession.shared.dataTask(with: url) { data, _, error in
        guard error == nil else {
            fatalError("Failed to fetch contents of \(url)")
        }

        guard let data = data else {
            fatalError("Data is empty for \(url)")
        }

        let files = try! JSONDecoder().decode([GHFileObject].self, from: data)
        completion(files)
    }.resume()
}

private func fetchWebsiteData(files: [GHFileObject], completion: @escaping ([WebsiteCategory]?) -> Void) {
    let excludedFiles = Set(["languages", "sections"])
    var result = [WebsiteCategory]()

    let dispatchGroup = DispatchGroup()

    for file in files {
        let url = URL(string: file.url)!
        if excludedFiles.contains(file.name) {
            continue
        }

        dispatchGroup.enter()
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer {
                dispatchGroup.leave()
            }

            guard error == nil else {
                fatalError("Failed to fetch contents of \(url)")
            }

            guard let data = data else {
                fatalError("Data is empty for \(url)")
            }

            guard let dataString = String(data: data, encoding: .utf8) else {
                fatalError("Failed to convert data to string")
            }

            var category = try! YAMLDecoder().decode(WebsiteCategory.self, from: dataString)
            category.name = file.name
            result.append(category)
        }.resume()
    }

    dispatchGroup.notify(queue: DispatchQueue.main) {
        completion(result)
    }
}
