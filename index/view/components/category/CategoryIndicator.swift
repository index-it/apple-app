//
//  CategoryIndicator.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/12/24.
//

import SwiftUI

struct CategoryIndicator: View {
    @Bindable var category: IxListCategory
    var selected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius)
                .fill(Color(hexString: category.color))
                .frame(width: CategoryUIDefaults.width, height: CategoryUIDefaults.height)

            if selected {
                Image(systemName: "plus")
                    .foregroundStyle(Color(hexString: category.color).contrastColor())
                    .font(CategoryUIDefaults.font)
            }
        }
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
