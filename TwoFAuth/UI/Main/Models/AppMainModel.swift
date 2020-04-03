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

final class AppMainModel: MainModel {
    override init(storage: Storage) {
        super.init(storage: storage)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(storageDidFailNotification(_:)),
                                       name: SyncableStorageNotification.didFail,
                                       object: storage)
    }
}

// MARK: Private

private extension AppMainModel {
    @objc
    func storageDidFailNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let error = userInfo[SyncableStorageNotification.errorKey] as? Error else {
            fatalError("Invalid Storage notification")
        }
        delegate?.mainModel(self,
                            showAlertWithTitle: LocalizedStrings.iCloudBackupError,
                            message: error.userDescription)
    }
}
