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

extension PersistentToken {
    func lastUpdateTime(before date: Date) -> Date {
        switch token.generator.factor {
        case .counter:
            return .distantPast
        case let .timer(period):
            let epoch = date.timeIntervalSince1970
            let timeInterval = epoch - epoch.truncatingRemainder(dividingBy: period)
            return Date(timeIntervalSince1970: timeInterval)
        }
    }

    func nextUpdateTime(after date: Date) -> Date {
        switch token.generator.factor {
        case .counter:
            return .distantFuture
        case let .timer(period):
            let epoch = date.timeIntervalSince1970
            let timeInterval = epoch + (period - epoch.truncatingRemainder(dividingBy: period))
            return Date(timeIntervalSince1970: timeInterval)
        }
    }
}
