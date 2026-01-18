//
//  Validatable.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

import Foundation

public protocol Validatable {
    var validationRes: Result<Void, ValidationError> { get }
}

public struct ValidationError: Error {
    public let message: LocalizedStringResource
    
    public init(_ message: LocalizedStringResource) {
        self.message = message
    }
}
