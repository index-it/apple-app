//
//  TrailIntentError.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//


import Foundation

/**
 An intent can throw custom `Error` values. If the `Error` conforms to `CustomLocalizedStringResourceConvertible`, the system will use
 the localized text as part of the error handling.
 */
enum IxIntentError: Error, CustomLocalizedStringResourceConvertible {
    case listNotFound
    case unknown
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .listNotFound:
            return "Could not find the related list."
        case .unknown:
            return "We messed up! The developers have been notified!"
        }
    }
}
