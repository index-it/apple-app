//
//  LongPressButtonStyle.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

import SwiftUI

struct SupportsLongPress: PrimitiveButtonStyle {
    let longPressAction: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onTapGesture {
                configuration.trigger()
            }
            .onLongPressGesture(
                perform: {
                    self.longPressAction()
                }
            )
    }
}

struct SupportsLongPressModifier: ViewModifier {
    let longPressAction: () -> Void
    func body(content: Content) -> some View {
        content.buttonStyle(SupportsLongPress(longPressAction: longPressAction))
    }
}

extension View {
    func supportsLongPress(longPressAction: @escaping () -> Void) -> some View {
        modifier(SupportsLongPressModifier(longPressAction: longPressAction))
    }
}
