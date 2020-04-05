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

extension NSMutableAttributedString {
    func hightlightSearchQuery(_ searchQuery: String, highlightedTextColor: UIColor) {
        if length <= (searchQuery as NSString).length || searchQuery.isEmpty {
            return
        }

        let textRange = NSRange(location: 0, length: length)
        let plainString = string as NSString
        let attributes = [NSAttributedString.Key.foregroundColor: highlightedTextColor]
        let queryItems = searchQuery.components(separatedBy: " ")

        for queryItem in queryItems {
            var searchRange = textRange
            var foundRange: NSRange
            while searchRange.location < textRange.length {
                searchRange.length = length - searchRange.location
                foundRange = plainString.range(of: queryItem,
                                               options: [.caseInsensitive, .diacriticInsensitive],
                                               range: searchRange)
                if foundRange.location != NSNotFound {
                    removeAttribute(NSAttributedString.Key.foregroundColor, range: foundRange)
                    addAttributes(attributes, range: foundRange)

                    searchRange.location = foundRange.location + foundRange.length
                }
                else {
                    break
                }
            }
        }
    }
}
