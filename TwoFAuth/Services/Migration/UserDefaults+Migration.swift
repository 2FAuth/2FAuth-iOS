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

extension UserDefaults {
    private enum Keys {
        static let migratedV1Key = AppDomain + ".migration.v1"
    }

    var isMigratedV1: Bool {
        get {
            bool(forKey: Keys.migratedV1Key)
        }
        set {
            set(newValue, forKey: Keys.migratedV1Key)
        }
    }
}
