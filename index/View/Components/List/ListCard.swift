//
//  ListCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import DynamicColor
import IxCoreKit

struct ListCard: View {
    var list: IxList
    var owner: Bool
    
    var onTap: () -> Void
    var onShare: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onLeave: () -> Void
    
    var withInteractions: Bool = true
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack {
                HStack {
                    Text(list.icon)
                        .font(.title)
                    
                    Spacer()
                    
                    if withInteractions {
                        Menu {
                            if owner {
                                Button("Sharing", systemImage: "person.2.badge.gearshape", action: onShare)
                            }
                            
                            Button("Edit", systemImage: "pencil", action: onEdit)
                            
                            if owner {
                                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                            } else {
                                Button("Leave", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: onLeave)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.20))
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "ellipsis")
                                    .foregroundColor(list.color.toColor().contrastColor())
                                    .fontWeight(.semibold)
                                    .font(.title3)
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    if (list.isShared) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundStyle(list.color.toColor().contrastColor())
                            .onTapGesture(perform: onShare)
                    }
                    
                    Text(list.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(list.color.toColor().contrastColor())
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
            .frame(height: 110)
        }
        .if(!withInteractions) { view in
            view.shadow(color: list.color.toColor().opacity(0.5), radius: 10)
        }
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20))
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
