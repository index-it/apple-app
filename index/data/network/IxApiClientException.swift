//
//  IxApiClientException.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation

enum IxApiClientError: Error {
    case Unknown
    case InvalidData
    case NetworkError
    case TooManyRequests
    
    case NotFound(EntityType)
    case MissingPermission(IxListPermission)
    case ProRequired(ProFeature)

    // MARK: Auth
    case Unauthenticated
    case EmailOrPasswordFormatInvalid
    case UnusableEmail
    case EmailNotVerified
    case TooManyVerificationEmails
    case TooManyPasswordForgottenEmails
}

extension IxApiClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .Unknown:
            return NSLocalizedString("Oh no something went terribly wrong, please try again later or contact Support.", comment: "generic unknown error")
            
        case .InvalidData:
            return NSLocalizedString("You entered some invalid values, please double check!", comment: "Invalid data error")

        case .NetworkError:
            return NSLocalizedString("A network error occurred. Please check your internet connection.", comment: "Network error")

        case .TooManyRequests:
            return NSLocalizedString("Too many requests. Please wait a moment and try again.", comment: "Rate limit error")

        case .NotFound(let entityType):
            return String(format: NSLocalizedString("%@ not found.", comment: "Entity not found error"), entityType.localizedDescription)

        case .MissingPermission(let permission):
            switch permission {
            case .list_viewer:
                return NSLocalizedString("You don't have permissions to view this list.", comment: "Missing list view permission error")
            case .list_editor:
                return NSLocalizedString("You don't have permissions to edit this list.", comment: "Missing list edit permission error")
            case .list_owner:
                return NSLocalizedString("Only the owner of the list can perform this action.", comment: "Missing list ownership error")
            }

        case .ProRequired(let feature):
            return String(format: NSLocalizedString("Hey this is a Pro feature: %@.", comment: "Pro feature required error"), feature.localizedDescription)

        case .Unauthenticated:
            return NSLocalizedString("You must be logged in to perform this action.", comment: "Unauthenticated error")

        case .EmailOrPasswordFormatInvalid:
            return NSLocalizedString("The email or password format is invalid.", comment: "Invalid email or password format error")

        case .UnusableEmail:
            return NSLocalizedString("The email you provided is not allowed to register, please use another email.", comment: "Unusable email error")

        case .EmailNotVerified:
            return NSLocalizedString("Your email address has not been verified. Please check your inbox and verify it to continue.", comment: "Email not verified error")

        case .TooManyVerificationEmails:
            return NSLocalizedString("You have requested too many verification emails, please check your spam folder for any previous email from us, consider checking your spam too!", comment: "Rate limit error for email verification")

        case .TooManyPasswordForgottenEmails:
            return NSLocalizedString("You requested too many password resets, please check the spam folder of your inbox if you can't find the email we sent you previously.", comment: "Rate limit error for password reset emails")
        
        }
    }
}
