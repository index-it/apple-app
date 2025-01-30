//
//  CustomButtonAnimation.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/01/25.
//
import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.smooth, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CustomButtonStyle {
    static var customButton: CustomButtonStyle { .init() }
}

#Preview {
    Button {
        
    } label: {
        HStack {
            Text("Hi")
                .padding()
        }.background(.green)
    }.buttonStyle(.customButton)
    
    
    Button {
        
    } label: {
        HStack {
            Text("Hello")
                .padding()
        }.background(.green)
    }
}
