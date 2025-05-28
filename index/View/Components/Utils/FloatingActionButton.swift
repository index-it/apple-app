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
        ZStack(alignment: .bottomTrailing) {
            content
            
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4, x: 0, y: 4)
            }
            .padding()
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
    }.frame(maxWidth: .infinity, maxHeight: .infinity).floatingActionButton("plus") {
        
    }
}
