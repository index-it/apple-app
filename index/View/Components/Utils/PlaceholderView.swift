//
//  Placeholder.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI

struct PlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.gray.opacity(0.2))
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
            .padding()
            .overlay {
                Text("Placeholder")
            }
    }
}
