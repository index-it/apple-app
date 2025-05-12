//
//  IxApiClientException.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation

public enum IxApiClientError: Error {
    case unknown
    case invalidData
    case networkError
    case tooManyRequests
    
    case notFound(EntityType)
    case missingPermission(IxListPermission)
    case proRequired(ProFeature)

    // MARK: Auth
    case unauthenticated
    case emailOrPasswordFormatInvalid
    case unusableEmail
    case emailNotVerified
    case tooManyVerificationEmails
    case tooManyPasswordForgottenEmails
}

extension IxApiClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown:
            return NSLocalizedString("Oh no something went terribly wrong, please try again later or contact Support.", comment: "generic unknown error")
            
        case .invalidData:
            return NSLocalizedString("You entered some invalid values, please double check!", comment: "Invalid data error")

        case .networkError:
            return NSLocalizedString("A network error occurred. Please check your internet connection.", comment: "Network error")

        case .tooManyRequests:
            return NSLocalizedString("Too many requests. Please wait a moment and try again.", comment: "Rate limit error")

        case .notFound(let entityType):
            return String(format: NSLocalizedString("%@ not found.", comment: "Entity not found error"), entityType.localizedDescription)

        case .missingPermission(let permission):
            switch permission {
            case .viewer:
                return NSLocalizedString("You don't have permissions to view this list.", comment: "Missing list view permission error")
            case .editor:
                return NSLocalizedString("You don't have permissions to edit this list.", comment: "Missing list edit permission error")
            case .owner:
                return NSLocalizedString("Only the owner of the list can perform this action.", comment: "Missing list ownership error")
            }

        case .proRequired(let feature):
            return String(format: NSLocalizedString("Hey this is a Pro feature: %@.", comment: "Pro feature required error"), feature.localizedDescription)

        case .unauthenticated:
            return NSLocalizedString("You must be logged in to perform this action.", comment: "Unauthenticated error")

        case .emailOrPasswordFormatInvalid:
            return NSLocalizedString("The email or password format is invalid.", comment: "Invalid email or password format error")

        case .unusableEmail:
            return NSLocalizedString("The email you provided is not allowed to register, please use another email.", comment: "Unusable email error")

        case .emailNotVerified:
            return NSLocalizedString("Your email address has not been verified. Please check your inbox and verify it to continue.", comment: "Email not verified error")

        case .tooManyVerificationEmails:
            return NSLocalizedString("You have requested too many verification emails, please check your spam folder for any previous email from us, consider checking your spam too!", comment: "Rate limit error for email verification")

        case .tooManyPasswordForgottenEmails:
            return NSLocalizedString("You requested too many password resets, please check the spam folder of your inbox if you can't find the email we sent you previously.", comment: "Rate limit error for password reset emails")
        
        }
    }
}
