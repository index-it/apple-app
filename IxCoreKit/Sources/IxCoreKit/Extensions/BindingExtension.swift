//
//  BindingExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

import SwiftUI

public func ?? <T: Sendable>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
