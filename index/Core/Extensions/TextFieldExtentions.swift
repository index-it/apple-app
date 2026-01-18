//
//  TextFieldExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/03/25.
//

import SwiftUI

func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
