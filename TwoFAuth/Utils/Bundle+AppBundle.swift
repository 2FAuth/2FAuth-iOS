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

extension Bundle {
    class var appBundle: Bundle {
        var bundle = Bundle.main

        #if APP_EXTENSION
            if bundle.bundleURL.pathExtension == "appex" {
                // iOSAppBundle.app/PlugIns/AppExtensionBundle.appex
                let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
                if let appBundle = Bundle(url: url) {
                    bundle = appBundle
                }
            }
        #endif /* APP_EXTENSION */

        return bundle
    }
}
