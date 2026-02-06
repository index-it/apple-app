//
//  EmojiHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/05/25.
//

import SwiftUI

public enum EmojiHelper {
    public static let emojiRanges: [UInt32] = [
        0x1F600 ... 0x1F64F,
        0x1F680 ... 0x1F6C5,
        0x1F6CB ... 0x1F6D2,
        0x1F6E0 ... 0x1F6E5,
        0x1F6F3 ... 0x1F6FA,
        0x1F7E0 ... 0x1F7EB,
        0x1F90D ... 0x1F93A,
        0x1F93C ... 0x1F945,
        0x1F947 ... 0x1F971,
        0x1F973 ... 0x1F976,
        0x1F97A ... 0x1F9A2,
        0x1F9A5 ... 0x1F9AA,
        0x1F9AE ... 0x1F9CA,
        0x1F9CD ... 0x1F9FF,
        0x1FA70 ... 0x1FA73,
        0x1FA78 ... 0x1FA7A,
        0x1FA80 ... 0x1FA82,
        0x1FA90 ... 0x1FA95,
    ].reduce([], +)

    public static let emojiRangesForPickerInitialEmoji: [UInt32] = [
        0x1F6CB ... 0x1F6D2,
        0x1F6E0 ... 0x1F6E5,
        0x1F93C ... 0x1F945,
        0x1FA78 ... 0x1FA7A,
        0x1FA90 ... 0x1FA95,
    ].reduce([], +)

    public static func randomEmoji() -> String {
        let ascii = emojiRanges[Int(drand48() * Double(emojiRanges.count))]
        let emoji = UnicodeScalar(ascii)?.description ?? "🎨"
        return emoji
    }

    public static func randomEmojiForPickerInitial() -> String {
        let ascii = emojiRangesForPickerInitialEmoji[Int(drand48() * Double(emojiRangesForPickerInitialEmoji.count))]
        let emoji = UnicodeScalar(ascii)?.description ?? "🎨"
        return emoji
    }
    
    public static func emojiImageData(_ emoji: String, size: CGFloat = 64) -> Data? {
        let font = UIFont.systemFont(ofSize: size)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = emoji.size(withAttributes: attributes)

        let renderer = UIGraphicsImageRenderer(size: textSize)
        let image = renderer.image { _ in
            emoji.draw(at: .zero, withAttributes: attributes)
        }

        return image.pngData()
    }
}
