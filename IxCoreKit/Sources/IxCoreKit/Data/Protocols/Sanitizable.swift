//
//  Sanitizable.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

public protocol Sanitizable {
    var sanitized: Self { get }
}

extension String {
    var sanitized: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var sanitizedNonEmpty: String? {
        sanitized.nonEmpty
    }
}
