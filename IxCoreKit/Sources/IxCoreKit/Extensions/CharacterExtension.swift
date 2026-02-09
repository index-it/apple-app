//
//  CharacterExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

public extension Character {
    var isEmoji: Bool {
        // Checks if the character is a scalar emoji or variant
        return self.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji }
    }
}
