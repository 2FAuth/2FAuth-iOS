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

#if SCREENSHOT

    import CloudSync
    import Foundation

    extension CommandLine {
        static var isDemoMode: Bool {
            arguments.contains("--demo-mode") || UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
        }
    }

    // MARK: - Services

    final class DemoServices: AppServices {
        let userDefaults: UserDefaults
        let favIconFetcher: FavIconFetcher
        let storage: SyncableStorage
        let authManager: AuthenticationManager
        let cloudConfig: CloudSync.Configuration
        let cloudPassphrase: PinManager

        init() {
            userDefaults = UserDefaults.standard
            favIconFetcher = FavIconFetcher()
            cloudConfig = AppProductionServices.createCloudSyncConfiguration()

            do {
                let cloudConfiguration = PinAttemptsConfiguration.cloudDebug()
                let cloudKeychain = PinKeychain(domain: "cloud-demo")
                cloudPassphrase = try PinManagerImpl(keychain: cloudKeychain,
                                                     secureTime: SecureTimeClock.shared,
                                                     configuration: cloudConfiguration)
            }
            catch {
                preconditionFailure("Failed to initialize Cloud PinManager: \(error)")
            }

            storage = DemoStorage()

            do {
                let configuration = PinAttemptsConfiguration.passcodeDebug()
                let passcodeKeychain = PinKeychain(domain: "passcode-demo")
                let passcode = try PinManagerImpl(keychain: passcodeKeychain,
                                                  secureTime: SecureTimeClock.shared,
                                                  configuration: configuration)
                try? passcode.deletePin()
                authManager = AuthenticationManager(passcode: passcode, userDefaults: userDefaults)
            }
            catch {
                preconditionFailure("Failed to initialize Passcode PinManager: \(error)")
            }
        }
    }

    // MARK: - Storage

    final class DemoStorage: SyncableStorage {
        private struct Error: Swift.Error {}

        let persistentTokens: [PersistentToken]

        init() {
            let tokens = [
                Token(
                    name: "johnny.appleseed@gmail.com",
                    issuer: "Google",
                    factor: .timer(period: 10)
                ),
                Token(
                    name: "johnnythedev",
                    issuer: "GitHub",
                    factor: .timer(period: 20)
                ),
                Token(
                    name: "justjohnny",
                    issuer: "Microsoft",
                    factor: .timer(period: 30)
                ),
                Token(
                    name: "johnny.appleseed@gmail.com",
                    issuer: "Amazon",
                    factor: .timer(period: 40)
                ),
                Token(
                    name: "johnnythedev",
                    issuer: "LinkedIn",
                    factor: .timer(period: 50)
                ),
            ]

            persistentTokens = tokens.map(PersistentToken.init(demoToken:))
        }

        func addToken(_ token: Token) throws -> PersistentToken {
            throw Error()
        }

        func updatePersistentToken(_ persistentToken: PersistentToken) throws {
            throw Error()
        }

        func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) {}

        func deletePersistentToken(_ persistentToken: PersistentToken) throws {
            throw Error()
        }

        func enableSync() {}

        func disableSync() {}

        func processSubscriptionNotification(with userInfo: [AnyHashable: Any],
                                             completion: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
            return false
        }
    }

    private extension Token {
        init(name: String = "", issuer: String = "", factor: Generator.Factor) {
            // swiftlint:disable:next force_unwrapping
            let generator = Generator(factor: factor, secret: Data(), algorithm: .sha1, digits: 6)!
            self.init(name: name, issuer: issuer, generator: generator)
        }
    }

    private extension PersistentToken {
        init(demoToken: Token) {
            self.init(token: demoToken, id: UUID().uuidString, ckData: nil)
        }
    }

    extension DateTime {
        static let demo = DateTime(date: Date(timeIntervalSince1970: 2_000_000_000))
    }

#endif /* SCREENSHOT */
