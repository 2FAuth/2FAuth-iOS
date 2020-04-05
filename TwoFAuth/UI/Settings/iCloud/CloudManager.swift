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

import UIKit

protocol CloudManager: AnyObject {
    var storage: SyncableStorage { get }
}

extension CloudManager where Self: UIViewController {
    func disableCloudSync(sender: UIView?, cancelCompletion: (() -> Void)? = nil) {
        let actionSheet = UIAlertController(title: LocalizedStrings.disableCloudBackup,
                                            message: LocalizedStrings.disableCloudBackupDescription,
                                            preferredStyle: sender == nil ? .alert : .actionSheet)

        let deleteAction = UIAlertAction(title: LocalizedStrings.deleteDataFromCloud, style: .destructive) { _ in
            self.storage.disableSync()
        }
        actionSheet.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: LocalizedStrings.cancel, style: .cancel) { _ in
            cancelCompletion?()
        }
        actionSheet.addAction(cancelAction)

        if let sender = sender, UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        }

        present(actionSheet, animated: true)
    }
}
