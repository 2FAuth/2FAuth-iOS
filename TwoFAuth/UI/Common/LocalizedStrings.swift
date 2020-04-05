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

// swiftlint:disable line_length

import Foundation

enum LocalizedStrings {
    static let appName = "2FAuth"
    static let ok = NSLocalizedString("OK", comment: "")
    static let next = NSLocalizedString("Next", comment: "")
    static let cameraAccessDeniedDescription = NSLocalizedString("Access to the camera is denied.", comment: "")
    static let cameraSetupFailedDescription = NSLocalizedString("Camera not available or does not support scanning QR codes.", comment: "")
    static let openSettings = NSLocalizedString("Open Settings", comment: "")
    static let cancel = NSLocalizedString("Cancel", comment: "")
    static let scanQRCode = NSLocalizedString("Scan QR Code", comment: "")
    static let unableToAddOneTimePassword = NSLocalizedString("Unable to add one-time password", comment: "")
    static let unableToUpdateOneTimePassword = NSLocalizedString("Unable to update one-time password", comment: "")
    static let unknownError = NSLocalizedString("Unknown error", comment: "")
    static let issuer = NSLocalizedString("Issuer", comment: "")
    static let website = NSLocalizedString("Website", comment: "")
    static let accountName = NSLocalizedString("Account Name", comment: "")
    static let accountNamePlaceholder = "example@domain.com"
    static let secretKey = NSLocalizedString("Secret Key", comment: "")
    static let timeBased = NSLocalizedString("Time Based", comment: "")
    static let counterBased = NSLocalizedString("Counter Based", comment: "")
    static let sixDigits = NSLocalizedString("6 Digits", comment: "")
    static let sevenDigits = NSLocalizedString("7 Digits", comment: "")
    static let eightDigits = NSLocalizedString("8 Digits", comment: "")
    static let advancedOptions = NSLocalizedString("Advanced Options", comment: "")
    static let settings = NSLocalizedString("Settings", comment: "")
    static let iCloudBackup = NSLocalizedString("iCloud Backup", comment: "")
    static let iCloudBackupDescription = NSLocalizedString("Synchronize one-time passwords via iCloud.\nYour data will be encrypted.", comment: "")
    static let iCloudBackupError = NSLocalizedString("iCloud Backup Error", comment: "")
    static let passcodeAndFaceID = NSLocalizedString("Passcode & Face ID", comment: "")
    static let passcodeAndTouchID = NSLocalizedString("Passcode & Touch ID", comment: "")
    static let passcode = NSLocalizedString("Passcode", comment: "")
    static let setupPasscodeDescription = NSLocalizedString("Passcode Lock\nAdditional passcode to enter the app.", comment: "")
    static let unlockWithFaceID = NSLocalizedString("Unlock with Face ID", comment: "")
    static let unlockWithTouchID = NSLocalizedString("Unlock with Touch ID", comment: "")
    static let acknowledgements = NSLocalizedString("Acknowledgements", comment: "")
    static let passcodeOptions = NSLocalizedString("Passcode Options", comment: "")
    static let passphraseOptions = NSLocalizedString("Passphrase Options", comment: "")
    static let turnPasscodeOn = NSLocalizedString("Turn Passcode On", comment: "")
    static let turnPasscodeOff = NSLocalizedString("Turn Passcode Off", comment: "")
    static let changePasscode = NSLocalizedString("Change Passcode", comment: "")
    static let enterAppPasscode = NSLocalizedString("Enter 2FAuth Passcode", comment: "")
    static let setUpAppPasscode = NSLocalizedString("Set Up 2FAuth Passcode", comment: "")
    static let enterYourNewPasscode = NSLocalizedString("Enter your new passcode", comment: "")
    static let verifyYourNewPasscode = NSLocalizedString("Verify your new passcode", comment: "")
    static let passcodesDidntMatch = NSLocalizedString("Passcodes did not match. Try again.", comment: "")
    static let fourDigitNumericCode = NSLocalizedString("4-Digit Numeric Code", comment: "")
    static let sixDigitNumericCode = NSLocalizedString("6-Digit Numeric Code", comment: "")
    static let customAlphanumericCode = NSLocalizedString("Custom Alphanumeric Code", comment: "")
    static let on = NSLocalizedString("On", comment: "")
    static let off = NSLocalizedString("Off", comment: "")
    static let delete = NSLocalizedString("Delete", comment: "")
    static let edit = NSLocalizedString("Edit", comment: "")
    static let manageOneTimePasswords = NSLocalizedString("Manage One-Time Passwords", comment: "")
    static let deleteOneTimePasswordSyncDisabledDescription = NSLocalizedString("Your one-time password will be permanently deleted from this device.", comment: "")
    static let deleteOneTimePasswordSyncEnabledDescription = NSLocalizedString("Your one-time password will be permanently deleted both from this device and iCloud.", comment: "")
    static let deleteOneTimePasswordFormat = NSLocalizedString("Confirm deletion of \"%@\"", comment: "")
    static let unnamedOneTimePassword = NSLocalizedString("Unnamed One-Time Password", comment: "")
    static let noOneTimePasswords = NSLocalizedString("No One-Time Passwords", comment: "")
    static let tapPlusToAddANewOneTimePassword = NSLocalizedString("Tap + to add a new one-time password", comment: "+ symbol MUST be presented in the string")
    static let addOneTimePassword = NSLocalizedString("Add One-Time Password", comment: "")
    static let addNewOneTimePasswordFormat = NSLocalizedString("Do you want to add a one-time password for \"%@\"?", comment: "")
    static let matched = NSLocalizedString("Matched", comment: "Items matching search query")
    static let nonmatched = NSLocalizedString("Nonmatched", comment: "Items not matching search query")

    static let about = NSLocalizedString("About", comment: "")
    static let thisAppIsOpenSource = NSLocalizedString("This app is open source", comment: "")
    static let rate2FAuth = NSLocalizedString("Rate 2FAuth", comment: "")
    static let contactUs = NSLocalizedString("Contact Us", comment: "")
    static let privacyPolicy = NSLocalizedString("Privacy Policy", comment: "")

    static let appIsDisabled = NSLocalizedString("2FAuth is disabled", comment: "")
    static let noSecureTimeDescription = NSLocalizedString("Cannot fetch secure time. Check your internet connection", comment: "")
    static let lockedForeverDescription = NSLocalizedString("No attempts left. Reinstall the app", comment: "")
    static let biometricsReason = NSLocalizedString("Authenticate to access your one-time passwords.", comment: "")
    static let operationNotAllowed = NSLocalizedString("Operation not allowed", comment: "")

    static let enablingCloudBackup = NSLocalizedString("Enabling iCloud Backup…", comment: "")
    static let setupCloudPassphrase = NSLocalizedString("Setup iCloud Passphrase", comment: "")
    static let setupCloudDescription = NSLocalizedString("A passphrase is required to encrypt your one-time passwords stored in iCloud. If you forget your passphrase, you won't be able to decrypt your saved records.", comment: "")
    static let enterYourCloudPassphrase = NSLocalizedString("Enter your iCloud encryption passphrase", comment: "")
    static let verifyYourCloudPassphrase = NSLocalizedString("Verify your iCloud encryption passphrase", comment: "")
    static let disableCloudBackup = NSLocalizedString("Disable iCloud Backup", comment: "")
    static let disableCloudBackupDescription = NSLocalizedString("Your one-time passwords will be deleted from iCloud. It will not affect one-time passwords stored on this device.", comment: "")
    static let deleteDataFromCloud = NSLocalizedString("Delete data from iCloud", comment: "")
    static let passphraseConfiguredDescription = NSLocalizedString("iCloud encryption passphrase is configured. For security reasons, you cannot view or modify it. To change it turn iCloud Backup off and on again.", comment: "")

    static let cannotDecodeDataFromCloud = NSLocalizedString("Cannot decode data from iCloud", comment: "")
    static let missingRequiredKeyURL = NSLocalizedString("Missing requried key 'URL'.", comment: "")
    static let missingRequiredKeySecret = NSLocalizedString("Missing requried key 'secret'.", comment: "")
    static let missingRequiredKeyPersistentIdentifiers = NSLocalizedString("Missing requried key 'persistentIdentifiers'.", comment: "")
    static let urlFieldIsInvalid = NSLocalizedString("'URL' field is invalid.", comment: "")
    static let oneTimePasswordDataIsInvalid = NSLocalizedString("One-time password data is invalid.", comment: "")
    static let makeSureYouEnterTheCorrectPassphrase = NSLocalizedString("Make sure you enter the correct passphrase.", comment: "")

    static let ckUserDeletedZone = NSLocalizedString("Backed up data was removed from iCloud.", comment: "")
    static let ckQuotaExceededFormat = NSLocalizedString("""
    Not Enough Storage\nThis %@ cannot be backed up because there is not enough iCloud storage available.
    You can manage your storage in Settings.
    """, comment: "...This iPhone cannot be backed up...")
    static let ckIncompatibleVersion = NSLocalizedString("Current app version is outdated. Please upgrade to the newest version of the app.", comment: "")
    static let ckAccountRequired = NSLocalizedString("An iCloud account is required to use the backup feature.\nYou can manage your iCloud account in Settings.", comment: "")

    static let crypterEncryptionFailure = NSLocalizedString("Failed to encrypt data to send to the iCloud.", comment: "")
    static let crypterDecryptionFailure = NSLocalizedString("Failed to decrypt data from iCloud.", comment: "")

    static func tryAgainIn(_ minutes: Int) -> String {
        let format = NSLocalizedString("try again in X minute(s)", comment: "")
        return String.localizedStringWithFormat(format, minutes)
    }

    static func attemptsLeft(_ attempts: UInt) -> String {
        let format = NSLocalizedString("X attempt(s) left", comment: "")
        return String.localizedStringWithFormat(format, attempts)
    }
}
