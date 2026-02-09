//
//  StringExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

public extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    var emoji: String? {
        first(where: { $0.isEmoji }).map { String($0) }
    }
}
