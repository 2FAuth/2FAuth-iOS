# 2FAuth

![Tests](https://github.com/2FAuth/2FAuth-iOS/workflows/Tests/badge.svg)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/2FAuth/2FAuth-iOS/blob/main/LICENSE)
[![Swift 5.1](https://img.shields.io/badge/swift-5.1-orange.svg)](#Getting-Started)
![Platform](https://img.shields.io/badge/platform-iOS-blue)

Two-Factor Authenticator App you dream about.

<p align="center">
<img src="https://github.com/2FAuth/2FAuth-iOS/raw/main/.assets/screenshots.png?raw=true" alt="2FAuth Screenshots" height="320">
</p>

[![Download on the AppStore](https://linkmaker.itunes.apple.com/en-gb/badge-lrg.svg?releaseDate=2017-07-19&kind=iossoftware&bubble=ios_apps)](https://apps.apple.com/app/2fauth/id1505207634)

## Features

* 100% free and fully open-sourced.
* Autofill codes with Safari Extension.
* Optional passcode or biometrics authentication inside the app.
* Optional iCloud Sync additionally encrypted with a user-provided passphrase.
* Works both on iPhone and iPad.
* Multitasking support on iPad (Slide Over and Split View).
* Fully supports Dynamic Type.
* Supports iOS 13 Dark Mode.
* Insanely performance-optimized and built with security in mind.

## Tech details

* Supports for time-based (TOTP) and counter-based (HOTP) code generation.
* Adding codes by `otpauth://` URL scheme.
* 2FAuth never sends your data anywhere unless you use iCloud Sync.
* Supports iOS 11 or later.

## Upcoming Features

* Apple Watch App

## Getting Started

1. Clone the repo `git clone https://github.com/2FAuth/2FAuth-iOS.git`
2. Fetch submodules `git submodule update --init`
3. Open `TwoFAuth.xcodeproj`

## Requirements

- Xcode 11
- iOS 11 or later

## Privacy Considerations

Your data never leaves your devices. If you enable iCloud Sync data will be transmitted to your private iCloud Database via CloudKit framework encrypted with AES256.

2FAuth uses [NTP protocol](https://en.wikipedia.org/wiki/Network_Time_Protocol) to get the current secure time . Feel free to use any traffic monitor (e.g., [Charles](https://www.charlesproxy.com)) to check it yourself.

All website favicons are bundled in the app. There's a standalone [internal tool](https://github.com/2FAuth/2FAuth-iOS/tree/main/TwoFAuthFavIconExporter) that uses https://twofactorauth.org database to fetch all websites supporting 2FA.

## Privacy Policy

See [PrivacyPolicy.txt](https://github.com/2FAuth/2FAuth-iOS/blob/main/PrivacyPolicy.txt)

## Special thanks

This app would not have been possible without an awesome [OneTimePassword](https://github.com/mattrubin/OneTimePassword) library from Matt Rubin.

## License

2FAuth is available under the MIT license. See the LICENSE file for more info.
