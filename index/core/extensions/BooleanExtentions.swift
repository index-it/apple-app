//
//  BooleanExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/12/24.
//

extension Bool: @retroactive Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        // the only true inequality is false < true
        !lhs && rhs
    }
}
