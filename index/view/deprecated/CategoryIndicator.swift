//
//  CategoryIndicator.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/12/24.
//

import SwiftUI
import DynamicColor

struct CategoryIndicator: View {
    @Bindable var category: IxListCategory
    var selected: Bool
    
    private var color: Color {
        Color(hexString: category.color)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        DynamicColor(color).lighter(amount: 0.07).toColor(),
                        color
                        
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: CategoryUIDefaults.width, height: CategoryUIDefaults.height)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            //                .shadow(color: Color(hexString: category.color).opacity(0.2), radius: 8)
            
            if selected {
                Image(systemName: "plus")
                    .foregroundStyle(Color(hexString: category.color).contrastColor())
                    .opacity(0.9)
                    .font(CategoryUIDefaults.font)
            }
        }.contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius))
    }
}

#Preview {
//    @Previewable @State var selected = true
    var selected = true
    
    CategoryIndicator(
        category: IxListCategory(
            id: "",
            user_id: "",
            list_id: "",
            name: "Test category",
            color: "#FF0000",
            created_at: 1700000
        ),
        selected: selected
    )
}
