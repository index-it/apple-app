//
//  FloatingActionButton.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/01/25.
//

import SwiftUI

struct FloatingActionButton: ViewModifier {
    let imageName: String
    let action: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: action) {
                        Image(systemName: imageName)
                            .foregroundColor(Color.accentColor.contrastColor())
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
    }
}

extension View {
    func floatingActionButton(_ imageName: String, action: @escaping () -> Void) -> some View {
        self.modifier(FloatingActionButton(imageName: imageName, action: action))
    }
}

#Preview {
    VStack {
        Text("Hi")
    }.floatingActionButton("plus") {
        
    }
}
