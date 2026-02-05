//
//  StringExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

public extension String {
    public var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
