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
import WatchKit

final class InterfaceController: WKInterfaceController {
    var model: WatchModel? {
        didSet {
            model?.delegate = self
            model?.update()
        }
    }

    var favIconFetcher: WatchFavIconFetcher?

    private var dataSource: WatchDataSource?

    @IBOutlet private var table: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}

extension InterfaceController: WatchModelDelegate {
    func watchModel(_ model: WatchModel, didUpdateDataSource dataSource: WatchDataSource) {
        self.dataSource = dataSource

        let rowType = String(describing: OneTimePasswordRow.self)
        table.setNumberOfRows(dataSource.items.count, withRowType: rowType)

        guard let progressModel = dataSource.progressModel else {
            assert(dataSource.items.isEmpty, "progressModel should exist")
            return
        }

        for (index, oneTimePassword) in dataSource.items.enumerated() {
            guard let row = table.rowController(at: index) as? OneTimePasswordRow else { return }
            row.favIconFetcher = favIconFetcher
            row.update(with: oneTimePassword, progressModel: progressModel)
        }
    }
}
