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

func update(categories: [WebsiteCategory], completion: @escaping ([Website]) -> Void) {
    var result = [Website]()
    var n = 0
    var total = 0
    for category in categories {
        for website in category.websites {
            let fileName = website.iconFileFullName
            let fullPath = (iconsDirFullPath as NSString).appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fullPath) {
                var modified = website
                modified.icon = fileName
                result.append(modified)
                n += 1
            }
            else {
                result.append(website)
            }
            total += 1
        }
    }

    print(">>> Found icons for \(n) of \(total) websites")

    completion(result)
}

func save(websites: [Website], completion: @escaping () -> Void) {
    print(">>> Saving websites data to the database")

    let persistentContainer = NSPersistentContainer(name: "TFASites")
    persistentContainer.loadPersistentStores { _, error in
        guard error == nil else {
            fatalError("\(String(describing: error))")
        }

        persistentContainer.performBackgroundTask { context in
            for website in websites {
                let entity = WebsiteEntity(context: context)
                entity.name = website.name
                entity.url = website.url
                entity.icon = website.icon
                entity.order = Int32(website.url.count)
            }

            try! context.save()

            completion()
        }
    }
}
