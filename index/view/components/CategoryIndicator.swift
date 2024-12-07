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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hexString: category.color))
                .id(category.id)
                .frame(width: 52, height: 52)
            
            if selected {
                Image(systemName: "plus")
                    .foregroundStyle(Color(hexString: category.color).contrastColor())
                    .font(.title)
                    .fontWeight(.semibold)
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
