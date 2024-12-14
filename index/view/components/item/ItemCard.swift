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
    
    var onOpen: (IxListItem) -> ()
    var onOpenLink: (IxListItem, String) -> ()
    var onCompletionChange: (IxListItem, Bool) -> ()
    var onCreateTask: (IxListItem) -> ()
    var onEdit: (IxListItem) -> ()
    var onDelete: (IxListItem) -> ()
    
    var body: some View {
        Menu {
            ControlGroup {
                Button("Open", systemImage: "text.page") {
                    onOpen(item)
                }
                
                if item.link != nil {
                    Button("Open link", systemImage: "link") {
                        if let link = item.link {
                            onOpenLink(item, link)
                        }
                    }
                }
                
                Button("Complete", systemImage: "checkmark") {
                    onCompletionChange(item, !item.completed)
                }
            }
            
            
            Button("Create task", systemImage: "rectangle.grid.1x2.fill") {
                onCreateTask(item)
            }
            
            Button("Edit", systemImage: "pencil") {
                onEdit(item)
            }
            
            Section {
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDelete(item)
                    }
                    
                    Button("Cancel", role: .cancel) {}
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            ItemCardContent
        }
        
    }
    
    var ItemCardContent: some View {
        HStack {
            Button {
                onCompletionChange(item, !item.completed)
            } label: {
                Label(item.completed ? "Uncomplete" : "Complete", systemImage: item.completed ? "inset.filled.circle" : "circle")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(item.completed ? Color.accentColor : .secondary)
            }
            
            Text(item.name)
                .multilineTextAlignment(.leading)
                
            if item.link != nil {
                Spacer()
                
                Button {
                    if let link = item.link {
                        onOpenLink(item, link)
                    }
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
    VStack {
        ItemCard(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: false,
                link: "https://google.com",
                created_at: 0,
                edited_at: 0,
                completed_at: nil
            ),
            onOpen: { _ in },
            onOpenLink: { _, _ in },
            onCompletionChange: { _, _ in },
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
        
        ItemCard(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: true,
                link: nil,
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            onOpen: { _ in },
            onOpenLink: { _, _ in },
            onCompletionChange: { _, _ in },
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
    }.padding()
}
