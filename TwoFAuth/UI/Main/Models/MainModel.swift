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

protocol MainModelDelegate: AnyObject {
    func mainModel(_ model: MainModel, didUpdateDataSource dataSource: MainDataSource)
    func mainModel(_ model: MainModel, showAlertWithTitle title: String, message: String)
}

class MainModel {
    private enum Constants {
        static let groupSize = 3
    }

    weak var delegate: MainModelDelegate?

    var isEmpty: Bool {
        storage.persistentTokens.isEmpty
    }

    var searchQuery: String? {
        didSet {
            update()
        }
    }

    private let storage: Storage

    private var updateTimer: Timer? {
        willSet {
            updateTimer?.invalidate()
        }
    }

    init(storage: Storage) {
        self.storage = storage

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(update),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(storageDidUpdateNotification(_:)),
                                       name: StorageNotification.didUpdate,
                                       object: storage)
    }

    @objc
    func update() {
        assert(delegate != nil)

        let query = trimmedSearchQuery()
        let persistentTokens = filteredTokens(persistentTokens: storage.persistentTokens, for: query)
        let date = DateTime.current.date
        let items = persistentTokens.map {
            OneTimePassword(persistentToken: $0, date: date, groupSize: Constants.groupSize)
        }

        let progressModel: ProgressModel?
        if persistentTokens.isEmpty {
            progressModel = nil
        }
        else {
            let lastUpdateTime = persistentTokens.reduce(.distantPast) { lastUpdateTime, persistentToken in
                max(lastUpdateTime, persistentToken.lastUpdateTime(before: date))
            }
            let nextUpdateTime = persistentTokens.reduce(.distantFuture) { nextUpdateTime, persistentToken in
                min(nextUpdateTime, persistentToken.nextUpdateTime(after: date))
            }

            progressModel = ProgressModel(startTime: lastUpdateTime, endTime: nextUpdateTime)

            setTimer(fireAt: nextUpdateTime)
        }

        let dataSource = MainDataSource(items: items, progressModel: progressModel)
        delegate?.mainModel(self, didUpdateDataSource: dataSource)
    }

    func stopUpdates() {
        updateTimer = nil
    }

    func addToken(_ token: Token) {
        do {
            try storage.addToken(token)
        }
        catch {
            delegate?.mainModel(self,
                                showAlertWithTitle: LocalizedStrings.unableToAddOneTimePassword,
                                message: error.localizedDescription)
        }
    }

    func copyPassword(for oneTimePassword: OneTimePassword) {
        let plainCode = oneTimePassword.plainCode()
        let pasteboard = UIPasteboard.general
        pasteboard.string = plainCode
    }

    func nextPassword(for oneTimePassword: OneTimePassword) {
        do {
            let updatedPersistentToken = oneTimePassword.persistentToken.nextPasswordToken()
            try storage.updatePersistentToken(updatedPersistentToken)
        }
        catch {
            delegate?.mainModel(self,
                                showAlertWithTitle: LocalizedStrings.unableToUpdateOneTimePassword,
                                message: error.localizedDescription)
        }
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

    private func trimmedSearchQuery() -> String? {
        guard let searchQuery = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines),
            !searchQuery.isEmpty else {
            return nil
        }
        return searchQuery
    }

    private func filteredTokens(persistentTokens: [PersistentToken], for query: String?) -> [PersistentToken] {
        guard let query = query else {
            return persistentTokens
        }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return persistentTokens.filter {
            $0.token.issuer.range(of: query, options: options) != nil ||
                $0.token.name.range(of: query, options: options) != nil
        }
    }
}

// MARK: Private

private extension MainModel {
    @objc
    func storageDidUpdateNotification(_ notification: Notification) {
        update()
    }
}

private extension PersistentToken {
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

extension DateTime {
    static var current: DateTime {
        #if SCREENSHOT && !APP_EXTENSION
            if CommandLine.isDemoMode {
                return DateTime.demo
            }
            else {
                return DateTime(date: Date())
            }
        #else
            return DateTime(date: Date())
        #endif /* SCREENSHOT */
    }
}
