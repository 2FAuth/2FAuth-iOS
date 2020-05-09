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

protocol WatchModelDelegate: AnyObject {
    func watchModel(_ model: WatchModel, didUpdateDataSource dataSource: WatchDataSource)
}

final class WatchModel {
    weak var delegate: WatchModelDelegate?

    private let storage: ReadonlyStorage

    private var updateTimer: Timer? {
        willSet {
            updateTimer?.invalidate()
        }
    }

    init(storage: ReadonlyStorage) {
        self.storage = storage

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(storageDidUpdateNotification(_:)),
                                       name: StorageNotification.didUpdate,
                                       object: storage)
    }

    @objc
    func update() {
        guard let delegate = delegate else { return }

        let persistentTokens = storage.persistentTokens
        let date = DateTime.current.date

        let progressModel: ProgressModel?
        if persistentTokens.isEmpty {
            progressModel = nil
        }
        else {
            progressModel = ProgressModel(persistentTokens: persistentTokens, date: date)
            setTimer(fireAt: progressModel!.endTime)
        }

        let oneTimePasswords = persistentTokens.map { OneTimePassword(persistentToken: $0, date: date) }
        let dataSource = WatchDataSource(items: oneTimePasswords, progressModel: progressModel)
        delegate.watchModel(self, didUpdateDataSource: dataSource)
    }

    func stopUpdates() {
        updateTimer = nil
    }

    // MARK: Private

    private func setTimer(fireAt date: Date) {
        let timer = Timer(fireAt: date,
                          interval: 0,
                          target: self,
                          selector: #selector(update),
                          userInfo: nil,
                          repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }
}

// MARK: Private

private extension WatchModel {
    @objc
    func storageDidUpdateNotification(_ notification: Notification) {
        update()
    }
}
