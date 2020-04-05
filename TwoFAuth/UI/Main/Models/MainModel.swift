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

    var matchQuery: String? {
        didSet {
            update()
        }
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
        guard let delegate = delegate else { return }

        let tokenSections = persistentTokenSections()
        let persistentTokens = tokenSections.reduce([], +)
        let date = DateTime.current.date

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

        let trimmedQuery = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let sections = tokenSections.map { tokens in
            ItemsSection(items: tokens.map {
                OneTimePassword(persistentToken: $0, searchQuery: trimmedQuery, date: date, groupSize: Constants.groupSize)
            })
        }

        let dataSource = MainDataSource(sections: sections, progressModel: progressModel)
        delegate.mainModel(self, didUpdateDataSource: dataSource)
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

    private func persistentTokenSections() -> [[PersistentToken]] {
        let allTokens = storage.persistentTokens

        // search has higher priority over matching
        if let searchQuery = searchQuery, searchQuery.isEmpty == false {
            let persistentTokens = filteredTokens(persistentTokens: allTokens, for: searchQuery)
            return [persistentTokens]
        }

        if let matchQuery = matchQuery, matchQuery.isEmpty == false {
            let matchedTokens = filteredTokens(persistentTokens: allTokens, for: matchQuery)
            if matchedTokens.isEmpty || matchedTokens.count == allTokens.count {
                return [allTokens]
            }

            let notMatchedTokens = allTokens.filter { matchedTokens.contains($0) == false }
            return [matchedTokens, notMatchedTokens]
        }

        return [allTokens]
    }

    private func filteredTokens(persistentTokens: [PersistentToken], for query: String) -> [PersistentToken] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return persistentTokens
        }

        let queryItems = trimmedQuery.components(separatedBy: " ")

        return persistentTokens.filter { persistentToken in
            queryItems.allSatisfy {
                let token = persistentToken.token
                return token.issuer.localizedStandardContains($0) || token.name.localizedStandardContains($0)
            }
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
