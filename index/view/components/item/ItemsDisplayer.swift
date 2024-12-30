//
//  ItemsDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI
import SwiftData

struct ItemsDisplayer: View {
    private var listId: String
    private var category: IxListCategory?
    
    private var itemFilter: ItemFilter
    private var onClearItemFilter: () -> ()

    private var onNewCategory: Bool
    
    private var onCreateItem: () -> ()
    private var onCreateCategory: () -> ()
    
    private var onOpen: (IxListItem) -> ()
    private var onOpenLink: (IxListItem, String) -> ()
    private var onCompletionChange: (IxListItem, Bool) -> ()
    private var onCreateTask: (IxListItem) -> ()
    private var onEdit: (IxListItem) -> ()
    private var onDelete: (IxListItem) -> ()
    
    @Query private var items: [IxListItem]
    
    private var color: Color? {
        guard let category = category else {
            return nil
        }
        
        return Color(hexString: category.color)
    }
    
    init(
        listId: String,
        category: IxListCategory? = nil,
        itemFilter: ItemFilter,
        itemSorting: ItemSorting,
        itemReverseSorting: Bool,
        onClearItemFilter: @escaping () -> (),
        onNewCategory: Bool,
        onCreateItem: @escaping () -> (),
        onCreateCategory: @escaping () -> (),
        onOpen: @escaping (IxListItem) -> Void,
        onOpenLink: @escaping (IxListItem, String) -> Void,
        onCompletionChange: @escaping (IxListItem, Bool) -> Void,
        onCreateTask: @escaping (IxListItem) -> Void,
        onEdit: @escaping (IxListItem) -> Void,
        onDelete: @escaping (IxListItem) -> Void
    ) {
        self.listId = listId
        self.category = category
        self.itemFilter = itemFilter
        self.onClearItemFilter = onClearItemFilter
        self.onNewCategory = onNewCategory
        
        self.onCreateItem = onCreateItem
        self.onCreateCategory = onCreateCategory
        self.onOpen = onOpen
        self.onOpenLink = onOpenLink
        self.onCompletionChange = onCompletionChange
        self.onCreateTask = onCreateTask
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let categoryId = category?.id
        
        var filterPredicate = #Predicate<IxListItem> { _ in true }
        
        if onNewCategory {
            filterPredicate = #Predicate<IxListItem> { _ in false }
        } else if itemFilter == .uncompleted {
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
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(items) { item in
                    SwipeView {
                        ItemCard(
                            item: item,
                            color: color,
                            onOpen: onOpen,
                            onOpenLink: onOpenLink,
                            onCompletionChange: onCompletionChange,
                            onCreateTask: onCreateTask,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )
                    } leadingActions: { _ in
                        SwipeAction("Test") {
                            // TODO
                        }
                    } trailingActions: { _ in
                        SwipeAction("World") {
                            // TODO
                        }
                    }
                    
                }
            }
        }.overlay {
            // MARK: Empty items overlay
            if items.isEmpty && !onNewCategory {
                VStack {
                    Spacer()
                    
                    ContentUnavailableView {
                        Label(itemFilter == .completed ? "No completed items" : "No items", systemImage: "binoculars")
                    } description: {
                        Text(itemFilter == .completed ? "You didn't complete any item yet" : "There are no items in this category")
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
            
            // MARK: New category overlay
            if onNewCategory {
                VStack {
                    Spacer()
                    
                    ContentUnavailableView {
                        Label("Need another category?", systemImage: "square.stack")
                    } description: {
                        Text("Create another category for your needs!")
                    } actions: {
                        Button {
                            onCreateCategory()
                        } label: {
                            Label("Create category", systemImage: "plus")
                        }.buttonStyle(.borderedProminent)
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
