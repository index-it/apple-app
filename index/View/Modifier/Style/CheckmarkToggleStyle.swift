//
//  CheckmarkToggleStyle.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI

struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
        })
    }
}

#Preview {
    Toggle(isOn: .constant(false)) {
        Text("Hi")
    }.toggleStyle(CheckmarkToggleStyle())

    Toggle(isOn: .constant(true)) {
        Text("Hi")
    }.toggleStyle(CheckmarkToggleStyle())
}
