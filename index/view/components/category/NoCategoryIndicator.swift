//
//  NoCategoryIndicator.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI
import DynamicColor

struct NoCategoryIndicator: View {
    var selected: Bool
    
    static private var color = Color.accentColor
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius)
                .fill(Color.accentColor)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        DynamicColor(Self.color).lighter(amount: 0.07).toColor(),
                        Self.color
                        
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: CategoryUIDefaults.width, height: CategoryUIDefaults.height)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

            if selected {
                Image(systemName: "plus")
                    .foregroundStyle(Color.accentColor.contrastColor())
                    .opacity(0.9)
                    .font(CategoryUIDefaults.font)
            }
        }.contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius))
    }
}

#Preview {
    var selected = true
    
    NoCategoryIndicator(selected: selected)
}
