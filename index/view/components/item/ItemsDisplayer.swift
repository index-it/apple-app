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
    private var withCompleted: Bool
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
        withCompleted: Bool,
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
        self.withCompleted = withCompleted
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
        
        if onNewCategory {
            _items = Query(filter: #Predicate { _ in false })
        } else if withCompleted {
            _items = Query(filter: #Predicate { item in
                item.list_id == listId && item.category_id == categoryId
            })
        } else {
            _items = Query(filter: #Predicate { item in
                item.list_id == listId && item.category_id == categoryId && item.completed == false
            })
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(items) { item in
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
                }
            }
        }.overlay {
            if items.isEmpty && !onNewCategory {
                VStack {
                    Spacer()
                    
                    ContentUnavailableView {
                        Label("No items", systemImage: "binoculars")
                    } description: {
                        Text("There are no items in this category")
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
