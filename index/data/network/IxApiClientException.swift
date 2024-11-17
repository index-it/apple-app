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
    
    case NotFound
    case MissingPermission
    case ProRequired

    /*
     AUTHENTICATION
     */
    case Unauthenticated
    case EmailOrPasswordFormatInvalid
    case UnusableEmail
    case EmailNotVerified
    case UserNotFound
}
