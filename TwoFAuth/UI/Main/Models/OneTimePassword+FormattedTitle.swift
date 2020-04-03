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

extension OneTimePassword {
    var formattedTitle: NSAttributedString? {
        if formattedTitleValue() == nil {
            let accountIsEmpty = account.isEmpty

            let result = NSMutableAttributedString()
            result.beginEditing()

            if !issuer.isEmpty {
                let string = accountIsEmpty ? issuer : issuer + ", "
                let attributes = [NSAttributedString.Key.foregroundColor: Styles.Colors.label]
                let attributedString = NSAttributedString(string: string, attributes: attributes)
                result.append(attributedString)
            }

            if !account.isEmpty {
                let attributes = [NSAttributedString.Key.foregroundColor: Styles.Colors.secondaryLabel]
                let attributedString = NSAttributedString(string: account, attributes: attributes)
                result.append(attributedString)
            }

            let titleAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)]
            let range = NSRange(location: 0, length: result.length)
            result.addAttributes(titleAttributes, range: range)

            result.endEditing()

            updateFormattedTitleValue(result)
        }
        return formattedTitleValue()
    }

    func resetFormattedValues() {
        updateFormattedTitleValue(nil)
    }
}
