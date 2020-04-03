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

protocol PasswordManaging: UIViewController {
    var userDefaults: UserDefaults { get }
    var storage: Storage { get }

    func delete(_ persistentToken: PersistentToken, sender: UIView)
}

extension PasswordManaging {
    func delete(_ persistentToken: PersistentToken, sender: UIView) {
        let title = String(format: LocalizedStrings.deleteOneTimePasswordFormat, persistentToken.displayName)
        let message: String
        if userDefaults.isCloudBackupEnabled {
            message = LocalizedStrings.deleteOneTimePasswordSyncEnabledDescription
        }
        else {
            message = LocalizedStrings.deleteOneTimePasswordSyncDisabledDescription
        }
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: LocalizedStrings.delete, style: .destructive) { _ in
            do {
                try self.storage.deletePersistentToken(persistentToken)
            }
            catch {
                self.display(error)
            }
        }
        actionSheet.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: LocalizedStrings.cancel, style: .cancel)
        actionSheet.addAction(cancelAction)

        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        }

        present(actionSheet, animated: true)
    }
}

extension PersistentToken {
    var displayName: String {
        switch (!token.name.isEmpty, !token.issuer.isEmpty) {
        case (true, true):
            return "\(token.issuer): \(token.name)"
        case (true, false):
            return token.name
        case (false, true):
            return token.issuer
        case (false, false):
            return LocalizedStrings.unnamedOneTimePassword
        }
    }
}
