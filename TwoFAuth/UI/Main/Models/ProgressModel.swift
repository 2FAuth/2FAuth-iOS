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

struct ProgressModel {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval

    @available(*, unavailable)
    init(startTime: Date, endTime: Date) {
        fatalError("init(startTime:, endTime:) has not been implemented")
    }

    init(persistentTokens: [PersistentToken], date: Date) {
        startTime = persistentTokens.reduce(.distantPast) { lastUpdateTime, persistentToken in
            max(lastUpdateTime, persistentToken.lastUpdateTime(before: date))
        }
        endTime = persistentTokens.reduce(.distantFuture) { nextUpdateTime, persistentToken in
            min(nextUpdateTime, persistentToken.nextUpdateTime(after: date))
        }
        duration = endTime.timeIntervalSince(startTime)
    }
}
