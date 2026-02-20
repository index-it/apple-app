//
//  FloatingActionButton.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/01/25.
//

import SwiftUI
import TipKit

struct FloatingActionButton: ViewModifier {
    let imageName: String
    let action: () -> Void
    let longPressAction: () -> Void
    let tip: (any Tip)?

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content

            if let tip {
                buttonView
                    .popoverTip(tip)
            } else {
                buttonView
            }
        }
    }
    
    var buttonView: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 4, x: 0, y: 4)
        }
        .supportsLongPress(longPressAction: longPressAction)
        .padding()
    }
}

extension View {
    func floatingActionButton(_ imageName: String, action: @escaping () -> Void, longPressAction: @escaping () -> Void, tip: (any Tip)? = nil) -> some View {
        modifier(
            FloatingActionButton(imageName: imageName, action: action, longPressAction: longPressAction, tip: tip)
        )
    }
}

#Preview {
    VStack {
        Text("Hi")
    }.frame(maxWidth: .infinity, maxHeight: .infinity).floatingActionButton("plus", action: {}, longPressAction: {})
}
