//
//  IxApiClientException.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation

enum IxApiClientError: Error {
    case Unknown
    case TooManyRequests

    /*
     AUTHENTICATION
     */
    case Unauthenticated
    case EmailOrPasswordFormatInvalid
    case UnusableEmail
    case EmailNotVerified
    case UserNotFound
}
