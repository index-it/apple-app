//
//  ItemsDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI
import SwiftData
import IxCoreKit

struct ItemsList: View {
    private var listId: String
    private var listColor: Color
    private var category: IxListCategory?
    
    private var showCompleted: Bool
    private var onClearItemFilter: () -> Void
    
    private var onCreateItem: () -> Void

    private var onOpenNotes: (IxListItem) -> ()
    private var onOpenLink: (IxListItem) -> ()
    private var onCompletionToggle: (IxListItem) -> ()
    private var onCreateTask: (IxListItem) -> ()
    private var onEdit: (IxListItem) -> ()
    private var onDelete: (IxListItem) -> ()
    
    @Query private var items: [IxListItem]
    
    private var color: Color {
        guard let category = category else { return listColor }
        return category.color.toColor()
    }
    
    init(
        listId: String,
        listColor: Color,
        category: IxListCategory?,
        showCompleted: Bool,
        sorting: ItemsSorting,
        sortOrder: SortOrder,
        onClearItemFilter: @escaping () -> Void,
        onCreateItem: @escaping () -> Void,
        onOpenNotes: @escaping (IxListItem) -> Void,
        onOpenLink: @escaping (IxListItem) -> Void,
        onCompletionToggle: @escaping (IxListItem) -> Void,
        onCreateTask: @escaping (IxListItem) -> Void,
        onEdit: @escaping (IxListItem) -> Void,
        onDelete: @escaping (IxListItem) -> Void
    ) {
        self.listId = listId
        self.listColor = listColor
        self.category = category
        self.showCompleted = showCompleted
        self.onClearItemFilter = onClearItemFilter
        self.onCreateItem = onCreateItem
        
        self.onOpenNotes = onOpenNotes
        self.onOpenLink = onOpenLink
        self.onCompletionToggle = onCompletionToggle
        self.onCreateTask = onCreateTask
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let categoryId = category?.id
        
        var filterPredicate = #Predicate<IxListItem> { _ in true }
        
        if !showCompleted {
            filterPredicate = #Predicate<IxListItem> { item in
                item.listId == listId && item.categoryId == categoryId && item.completed == false
            }
        } else {
            filterPredicate = #Predicate<IxListItem> { item in
                item.listId == listId && item.categoryId == categoryId
            }
        }
        
        // TODO: Manual
        let sortDescriptor = switch sorting {
        case .name:
            SortDescriptor(\IxListItem.name, order: sortOrder)
        case .creationDate:
            SortDescriptor(\IxListItem.createdAt, order: sortOrder)
        case .manual:
            SortDescriptor(\IxListItem.editedAt, order: sortOrder)
        }
       
        _items = Query(filter: filterPredicate, sort: [SortDescriptor(\IxListItem.completed), sortDescriptor])
    }
    
    var body: some View {
        List(items) { item in
            ItemRow(
                item: item,
                color: color,
                onOpenNotes: onOpenNotes,
                onOpenLink: onOpenLink,
                onCompletionToggle: onCompletionToggle,
                onCreateTask: onCreateTask,
                onEdit: onEdit,
                onDelete: onDelete
            ).swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete(item)
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    onCompletionToggle(item)
                } label: {
                    Label(item.completed ? "Uncomplete" : "Complete", systemImage: item.completed ? "xmark" : "checkmark")
                }.tint(item.completed ? .orange : .accentColor)
            }
        }.overlay {
            // MARK: Empty items overlay
            if items.isEmpty {
                VStack {
                    Spacer()
                    
                    ContentUnavailableView {
                        Label("No items", systemImage: "binoculars")
                    } description: {
                        Text(category == nil ? "There are no uncategorized items" : "There are no items in this category") // TODO
                    } actions: {
                        Button {
                            onCreateItem()
                        } label: {
                            Label("Create item", systemImage: "plus")
                        }.buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                }.frame(maxHeight: .infinity)
            }
        }
    }
}
