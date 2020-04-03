//
//  CKError+Storage.swift
//  CloudKitNotes
//
//  Created by Andrew Podkovyrin on 2/28/20.
//  Copyright © 2020 AP. All rights reserved.
//

import CloudKit
import UIKit

extension Error {
    var userDescription: String {
        guard let ckError = self as? CKError else { return localizedDescription }

        switch ckError.code {
        case .userDeletedZone:
            return LocalizedStrings.ckUserDeletedZone
        case .quotaExceeded:
            return String(format: LocalizedStrings.ckQuotaExceededFormat, UIDevice.current.model)
        case .incompatibleVersion:
            return LocalizedStrings.ckIncompatibleVersion
        case .managedAccountRestricted, .notAuthenticated:
            return LocalizedStrings.ckAccountRequired
        default:
            return localizedDescription
        }
    }
}
