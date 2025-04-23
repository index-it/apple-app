//
//  ItemsDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI
import SwiftData

struct ItemsList: View {
    private var listId: String
    private var listColor: Color
    private var category: IxListCategory?
    
    private var itemFilter: ItemFilter
    private var onClearItemFilter: () -> Void
    
    private var onCreateItem: () -> Void

    private var onOpenNotes: (IxListItem) -> ()
    private var onOpenLink: (IxListItem, String) -> ()
    private var onCompletionChange: (IxListItem, Bool) -> ()
    private var onCreateTask: (IxListItem) -> ()
    private var onEdit: (IxListItem) -> ()
    private var onDelete: (IxListItem) -> ()
    
    @Query private var items: [IxListItem]
    
    private var color: Color {
        guard let category = category else { return listColor }
        return Color(hexString: category.color)
    }
    
    init(
        listId: String,
        listColor: Color,
        category: IxListCategory?,
        itemFilter: ItemFilter,
        itemSorting: ItemSorting,
        itemReverseSorting: Bool,
        onClearItemFilter: @escaping () -> Void,
        onCreateItem: @escaping () -> Void,
        onOpenNotes: @escaping (IxListItem) -> Void,
        onOpenLink: @escaping (IxListItem, String) -> Void,
        onCompletionChange: @escaping (IxListItem, Bool) -> Void,
        onCreateTask: @escaping (IxListItem) -> Void,
        onEdit: @escaping (IxListItem) -> Void,
        onDelete: @escaping (IxListItem) -> Void
    ) {
        self.listId = listId
        self.listColor = listColor
        self.category = category
        self.itemFilter = itemFilter
        self.onClearItemFilter = onClearItemFilter
        self.onCreateItem = onCreateItem
        
        self.onOpenNotes = onOpenNotes
        self.onOpenLink = onOpenLink
        self.onCompletionChange = onCompletionChange
        self.onCreateTask = onCreateTask
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let categoryId = category?.id
        
        var filterPredicate = #Predicate<IxListItem> { _ in true }
        
        if itemFilter == .uncompleted {
            filterPredicate = #Predicate<IxListItem> { item in
                item.list_id == listId && item.category_id == categoryId && item.completed == false
            }
        } else if itemFilter == .all {
            filterPredicate = #Predicate<IxListItem> { item in
                item.list_id == listId && item.category_id == categoryId
            }
        } else if itemFilter == .completed {
            filterPredicate = #Predicate<IxListItem> { item in
                item.list_id == listId && item.category_id == categoryId && item.completed == true
            }
        }
        
        let sortOrder = if itemReverseSorting {
            SortOrder.reverse
        } else {
            SortOrder.forward
        }
        
        let sortDescriptor = switch itemSorting {
        case .name:
            SortDescriptor(\IxListItem.name, order: sortOrder)
        case .creation:
            SortDescriptor(\IxListItem.created_at, order: sortOrder)
        case .edit:
            SortDescriptor(\IxListItem.edited_at, order: sortOrder)
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
                onCompletionChange: onCompletionChange,
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
                    onCompletionChange(item, !item.completed)
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
                        if itemFilter == .completed {
                            Button {
                                onClearItemFilter()
                            } label: {
                                Label("Clear filters", systemImage: "xmark")
                            }.buttonStyle(.borderedProminent)
                        } else {
                            Button {
                                onCreateItem()
                            } label: {
                                Label("Create item", systemImage: "plus")
                            }.buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Spacer()
                }.frame(maxHeight: .infinity)
            }
        }
    }
}

#Preview {
//    ItemsDisplayer(
//        listId: "1",
//        categoryId: nil,
//        withCompleted: false
//    )
}
