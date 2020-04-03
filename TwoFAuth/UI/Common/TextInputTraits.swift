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

protocol TextInputTraits: AnyObject {
    var autocapitalizationType: UITextAutocapitalizationType { get set }
    var autocorrectionType: UITextAutocorrectionType { get set }
    var spellCheckingType: UITextSpellCheckingType { get set }
    var smartQuotesType: UITextSmartQuotesType { get set }
    var smartDashesType: UITextSmartDashesType { get set }
    var smartInsertDeleteType: UITextSmartInsertDeleteType { get set }
    var keyboardType: UIKeyboardType { get set }
    var keyboardAppearance: UIKeyboardAppearance { get set }
    var returnKeyType: UIReturnKeyType { get set }
    var enablesReturnKeyAutomatically: Bool { get set }
    var isSecureTextEntry: Bool { get set }
    var textContentType: UITextContentType! { get set }
}

extension UITextField: TextInputTraits {}

extension TextInputTraits {
    func configureAsIssuerInput() {
        autocapitalizationType = .none
        autocorrectionType = .no
        keyboardType = .URL
    }

    func configureAsAccountNameInput() {
        autocapitalizationType = .none
        autocorrectionType = .no
        keyboardType = .emailAddress
    }
}
