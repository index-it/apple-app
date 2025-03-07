//
//  ItemCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI
import DynamicColor

struct ItemRow: View {
    @Environment(\.colorScheme) var colorScheme
    var item: IxListItem
    var color: Color?
    
    var onOpenNotes: (IxListItem) -> ()
    var onOpenLink: (IxListItem, String) -> ()
    var onCompletionChange: (IxListItem, Bool) -> ()
    var onCreateTask: (IxListItem) -> ()
    var onEdit: (IxListItem) -> ()
    var onDelete: (IxListItem) -> ()
    
    var body: some View {
        HStack {
            Menu {
                ControlGroup {
                    if item.note != nil && !item.note!.isEmpty {
                        Button("See notes", systemImage: "text.page") {
                            onOpenNotes(item)
                        }
                    }
                    
                    if item.link != nil {
                        Button("Open link", systemImage: "link") {
                            if let link = item.link {
                                onOpenLink(item, link)
                            }
                        }
                    }
                }
                
                Button(item.completed ? "Uncomplete" : "Complete", systemImage: item.completed ? "xmark" : "checkmark") {
                    onCompletionChange(item, !item.completed)
                }
                
                
                Button("Create task", systemImage: "rectangle.grid.1x2.fill") {
                    onCreateTask(item)
                }
                
                Section {
                    Button("Edit", systemImage: "pencil") {
                        onEdit(item)
                    }
                    
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
                ItemRowContent
            }
            
            HStack(spacing: 8) {
                if item.note != nil {
                    Button {
                        onOpenNotes(item)
                    } label: {
                        Label("See notes", systemImage: "text.page")
                            .labelStyle(.iconOnly)
                            .fontWeight(.bold)
                            .padding(6)
                            .foregroundStyle(color?.contrastColor() ?? UIColor.label.toColor())
                    }.background(Color.clear)
                }
                
                if item.link != nil {
                    Button {
                        if let link = item.link {
                            onOpenLink(item, link)
                        }
                    } label: {
                        Label("Open link", systemImage: "link")
                            .labelStyle(.iconOnly)
                            .fontWeight(.bold)
                            .padding(6)
                            .foregroundStyle(color?.contrastColor() ?? UIColor.label.toColor())
                    }.background(Color.clear)
                }
            }.frame(alignment: .trailing)
        }.listRowBackground(color)
    }
    
    // MARK: Item card
    var ItemRowContent: some View {
        HStack {
            if item.completed {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
            }
            
            Text(item.name)
                .multilineTextAlignment(.leading)
            
        }.frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(color?.contrastColor() ?? UIColor.label.toColor())
    }
}

#Preview {
    List {
        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item very long nam",
                completed: true,
                link: "https://google.com",
                note: "Hi",
                created_at: 0,
                edited_at: 0,
                completed_at: nil
            ),
            color: Color.green,
            onOpenNotes: { _ in },
            onOpenLink: { _, _ in },
            onCompletionChange: { _, _ in },
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
        
        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: false,
                link: nil,
                note: "hello",
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            color: .orange,
            onOpenNotes: { _ in },
            onOpenLink: { _, _ in },
            onCompletionChange: { _, _ in },
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
        
        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: true,
                link: "Hii",
                note: nil,
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            onOpenNotes: { _ in },
            onOpenLink: { _, _ in },
            onCompletionChange: { _, _ in },
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
        
        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: true,
                link: nil,
                note: nil,
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            onOpenNotes: { _ in },
            onOpenLink: { _, _ in },
            onCompletionChange: { _, _ in },
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
    }.padding()
}
