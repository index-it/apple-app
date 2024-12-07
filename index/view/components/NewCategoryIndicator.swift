//
//  NewCategoryIndicator.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import SwiftUI

struct NewCategoryIndicator: View {
    var selected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(width: 52, height: 52)
            
            if selected {
                Image(systemName: "plus")
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
//    @Previewable @State var selected = true
    var selected = true
    
    NewCategoryIndicator(
        selected: selected
    )
}

