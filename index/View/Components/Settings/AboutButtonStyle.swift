//
//  AboutButtonStyle.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/03/25.
//

import SwiftUI

struct AboutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGray5))
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(Color.primary.opacity(0.7))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    Button("Review App", systemImage: "heart") {}
        .buttonStyle(AboutButtonStyle())
        .padding()
}
