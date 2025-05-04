//
//  ArrayExtensions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 14/03/25.
//

public extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
