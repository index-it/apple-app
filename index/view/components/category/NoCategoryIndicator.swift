//
//  NoCategoryIndicator.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI

struct NoCategoryIndicator: View {
    var selected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius)
                .fill(Color.accentColor)
                .frame(width: CategoryUIDefaults.width, height: CategoryUIDefaults.height)

            if selected {
                Image(systemName: "plus")
                    .foregroundStyle(Color.accentColor.contrastColor())
                    .font(CategoryUIDefaults.font)
            }
        }
    }
}

#Preview {
    var selected = true
    
    NoCategoryIndicator(selected: selected)
}
