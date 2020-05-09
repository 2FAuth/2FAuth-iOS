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
import os.log

/// Object to transfer between iOS and watchOS apps
struct PersistentTokenData: Identifiable, Codable {
    let id: String
    let url: URL
    let secret: Data
}

extension PersistentTokenData {
    init?(persistentToken: PersistentToken) {
        let token = persistentToken.token
        let url: URL
        do {
            url = try token.toURL()
        }
        catch {
            os_log("Failed to encode Token %@", log: .default, type: .error, String(describing: error))
            return nil
        }
        self.init(id: persistentToken.id, url: url, secret: token.generator.secret)
    }

    var persistentToken: PersistentToken? {
        let token: Token
        do {
            token = try Token(_url: url, secret: secret)
        }
        catch {
            os_log("Failed to decode Token %@", log: .default, type: .error, String(describing: error))
            return nil
        }
        return PersistentToken(token: token, id: id, ckData: nil)
    }
}
