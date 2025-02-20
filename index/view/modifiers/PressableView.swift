//
//  PressableView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 31/01/25.
//

import SwiftUI

struct PressEffect: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? 0.6 : 1)
//            .scaleEffect(isPressed ? 0.9 : 1)
            .animation(.smooth, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .onChange(of: isPressed) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPressed = false
                    }
                }
            }
    }
}

extension View {
    func pressEffect() -> some View {
        self.modifier(PressEffect())
    }
}
