//
//  EmojiHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/05/25.
//

import Foundation

public struct EmojiHelper {
    public static let emojiRanges: [UInt32] = [
        0x1f600...0x1f64f,
        0x1f680...0x1f6c5,
        0x1f6cb...0x1f6d2,
        0x1f6e0...0x1f6e5,
        0x1f6f3...0x1f6fa,
        0x1f7e0...0x1f7eb,
        0x1f90d...0x1f93a,
        0x1f93c...0x1f945,
        0x1f947...0x1f971,
        0x1f973...0x1f976,
        0x1f97a...0x1f9a2,
        0x1f9a5...0x1f9aa,
        0x1f9ae...0x1f9ca,
        0x1f9cd...0x1f9ff,
        0x1fa70...0x1fa73,
        0x1fa78...0x1fa7a,
        0x1fa80...0x1fa82,
        0x1fa90...0x1fa95,
    ].reduce([], +)
    
    public static let emojiRangesForPickerInitialEmoji: [UInt32] = [
        0x1f6cb...0x1f6d2,
        0x1f6e0...0x1f6e5,
        0x1f93c...0x1f945,
        0x1fa78...0x1fa7a,
        0x1fa90...0x1fa95,
    ].reduce([], +)
    
    public static func randomEmoji() -> String {
        let ascii = emojiRanges[Int(drand48() * (Double(emojiRanges.count)))]
        let emoji = UnicodeScalar(ascii)?.description ?? "🎨"
        return emoji
    }
    
    public static func randomEmojiForPickerInitial() -> String {
        let ascii = emojiRangesForPickerInitialEmoji[Int(drand48() * (Double(emojiRangesForPickerInitialEmoji.count)))]
        let emoji = UnicodeScalar(ascii)?.description ?? "🎨"
        return emoji
    }
}
