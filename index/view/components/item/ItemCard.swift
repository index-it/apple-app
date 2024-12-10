//
//  ItemCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI

struct ItemCard: View {
    var item: IxListItem
    var color: Color?
    
    var body: some View {
        HStack {
            Image(systemName: item.completed ? "inset.filled.circle" : "circle")
                .font(.title3)
                
                .opacity(0.5)
            
            Text(item.name)
                .multilineTextAlignment(.leading)
                
            if item.link != nil {
                Spacer()
                
                Button {
                    
                } label: {
                    Label("Open link", systemImage: "link")
                        .labelStyle(.iconOnly)
                }
            }
        }.padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(color?.contrastColor() ?? UIColor.label.toColor())
            .background(color ?? UIColor.secondarySystemBackground.toColor())
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ItemCard(item: IxListItem.loading())
        .padding()
}
