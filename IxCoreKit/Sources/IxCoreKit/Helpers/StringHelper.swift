//
//  StringHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import Foundation

public enum StringHelper {
    private static let trimmingCharactersSet: CharacterSet = .whitespacesAndNewlines.union(.punctuationCharacters)

    /// Returns the similarity score from 0 to 1 for two strings, using levenshtein distance algorithm
    public static func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let s1Normalized = s1.lowercased().trimmingCharacters(in: trimmingCharactersSet)
        let s2Normalized = s2.lowercased().trimmingCharacters(in: trimmingCharactersSet)

        let longer = s1Normalized.count > s2Normalized.count ? s1Normalized : s2Normalized

        if longer.isEmpty {
            return 1.0
        }

        let editDistance = levenshtein(sourceString: s1Normalized, target: s2Normalized)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
}
