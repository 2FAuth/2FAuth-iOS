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
import os.log

final class WebsiteCatalog {
    private static let containerName = "TFASites"
    private static let storeExtension = "sqlite"
    private let log = OSLog(subsystem: AppDomain, category: String(describing: WebsiteCatalog.self))

    private let persistentContainer: NSPersistentContainer

    init() {
        let name = WebsiteCatalog.containerName
        let ext = WebsiteCatalog.storeExtension
        let directory = NSPersistentContainer.defaultDirectoryURL()
        let storeURL = directory.appendingPathComponent(name, isDirectory: false).appendingPathExtension(ext)

        guard let defaultStoreURL = Bundle.appBundle.url(forResource: name, withExtension: ext) else {
            preconditionFailure("Website catalog database is missing")
        }

        let fileManager = FileManager.default

        do {
            try fileManager.removeItem(at: storeURL)
        }
        catch {
            if fileManager.fileExists(atPath: storeURL.path) {
                os_log("Failed to remove old database: '%{public}@'", log: log, type: .debug, String(describing: error))
            }
        }

        // We copy the bundled database per target (app / extension) since the user may
        // run app and extension simultaneously which leads to crash

        do {
            try fileManager.copyItem(at: defaultStoreURL, to: storeURL)
        }
        catch {
            os_log("Failed to copy default database: '%{public}@'", log: log, type: .debug, String(describing: error))
        }

        persistentContainer = NSPersistentContainer(name: name)
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                os_log("Failed to load persistent store: '%{public}@'", log: self.log, type: .debug, String(describing: error))
            }
        }
    }

    func fetchWebsiteIconName(for query: String, completion: @escaping (String?) -> Void) {
        persistentContainer.performBackgroundTask { context in
            let predicate = NSPredicate(format: "(%K CONTAINS[cd] %@) OR (%K CONTAINS[cd] %@)",
                                        #keyPath(WebsiteEntity.name), query,
                                        #keyPath(WebsiteEntity.url), query)
            let sortDescriptor = NSSortDescriptor(key: #keyPath(WebsiteEntity.order), ascending: true)
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = WebsiteEntity.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            fetchRequest.sortDescriptors = [sortDescriptor]

            let entity = try? context.fetch(fetchRequest).first as? WebsiteEntity
            let icon = entity?.icon

            DispatchQueue.main.async {
                completion(icon)
            }
        }
    }
}
