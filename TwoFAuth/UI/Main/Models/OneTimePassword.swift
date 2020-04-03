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

final class OneTimePassword {
    let persistentToken: PersistentToken
    var issuer: String { persistentToken.token.issuer }

    var account: String { persistentToken.token.name }

    let code: String
    let canManualRefresh: Bool

    private var _formattedTitle: NSAttributedString?

    init(persistentToken: PersistentToken, date: Date, groupSize: Int) {
        self.persistentToken = persistentToken
        let token = persistentToken.token
        let password = (try? token.generator.password(at: date)) ?? ""
        code = password.split(by: groupSize)

        if case .counter = token.generator.factor {
            canManualRefresh = true
        }
        else {
            canManualRefresh = false
        }
    }
}

// MARK: Equatable

extension OneTimePassword: Equatable {
    static func == (lhs: OneTimePassword, rhs: OneTimePassword) -> Bool {
        lhs === rhs
    }
}

// MARK: Hashable

extension OneTimePassword: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentToken)
    }
}

// MARK: Getting Value

extension OneTimePassword {
    func plainCode() -> String {
        code.removeWhitespaces()
    }
}

// MARK: Internal

extension OneTimePassword {
    func formattedTitleValue() -> NSAttributedString? {
        _formattedTitle
    }

    func updateFormattedTitleValue(_ formattedTitle: NSAttributedString?) {
        _formattedTitle = formattedTitle
    }
}
