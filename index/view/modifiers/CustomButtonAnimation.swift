//
//  CustomButtonAnimation.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/01/25.
//
import SwiftUI

struct OpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.smooth, value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == OpacityButtonStyle {
    static var opacity: OpacityButtonStyle { .init() }
}

#Preview {
    Button {
        
    } label: {
        HStack {
            Text("Hi")
                .padding()
        }.background(.green)
    }.buttonStyle(.opacity)
    
    
    Button {
        
    } label: {
        HStack {
            Text("Hello")
                .padding()
        }.background(.green)
    }
}
