//
//  ListCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import DynamicColor

struct ListCard: View {
    var list: IxList
    var onTap: () -> Void
    var onShare: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var withInteractions: Bool = true

    var body: some View {
        VStack {
            HStack {
                Text(list.icon)
                    .font(.title)
                
                Spacer()
                
                if withInteractions {
                    Menu {
                        Button("Sharing", systemImage: "person.2.badge.gearshape", action: onShare)
                        
                        Button("Edit", systemImage: "pencil", action: onEdit)
                        
                        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.20))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "ellipsis")
                                .foregroundColor(list.color.toColor(fallback: .white).contrastColor())
                                .fontWeight(.semibold)
                                .font(.title3)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                if (list.isShared()) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(list.color.toColor(fallback: .white).contrastColor())
                        .onTapGesture(perform: onShare)
                }
                
                Text(list.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(list.color.toColor(fallback: .white).contrastColor())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DynamicColor(hexString: list.color).lighter(amount: 0.07).toColor(),
                            DynamicColor(hexString: list.color).toColor()
                            
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .frame(height: 120)
        .onTapGesture(perform: onTap)
        .if(withInteractions) { view in
            // TODO: Fix white edges on context menu
            view.contextMenu {
                Button{
                    onShare()
                } label: {
                    Label("Share", systemImage: "person.2.badge.gearshape")
                }
                
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    let sampleList = IxList(
        id: "1",
        userId: "user123",
        name: "Email Album Art",
        emoji: "🌟",
        color: "#FF5733", // Sample color
        isPublic: true,
        viewers: ["user456", "user789"],
        editors: ["user123"],
        createdAt: 1697836800,
        editedAt: nil
    )
    
    ListCard(list: sampleList, onTap: {}, onShare: {}, onEdit: {}, onDelete: {})
        .padding()
        .frame(width: 250)
}
