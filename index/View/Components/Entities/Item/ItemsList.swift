//
//  ItemsList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import IxCoreKit
import SwiftData
import SwiftUI

struct ItemsList: View {
    private var listId: String
    private var listColor: Color
    private var category: IxListCategory?
    private var categories: [IxListCategory]

    private var showCompleted: Bool
    private var onClearItemFilter: () -> Void

    private var onCreateItem: () -> Void

    private var onOpenNotes: (IxListItem) -> Void
    private var onOpenLink: (IxListItem) -> Void
    private var onCompletionToggle: (IxListItem) -> Void
    private var onCategorize: (IxListItem, IxListCategory?) -> Void
    private var onCreateCategory: () -> Void
    private var onCreateTask: (IxListItem) -> Void
    private var onEdit: (IxListItem) -> Void
    private var onDelete: (IxListItem) -> Void

    @Query private var items: [IxListItem]

    private var color: Color {
        guard let categoryColor = category?.color else { return listColor }
        return categoryColor.toColor()
    }

    init(
        listId: String,
        listColor: Color,
        category: IxListCategory?,
        categories: [IxListCategory],
        showCompleted: Bool,
        sorting: ItemsSorting,
        sortOrder: SortOrder,
        onClearItemFilter: @escaping () -> Void,
        onCreateItem: @escaping () -> Void,
        onOpenNotes: @escaping (IxListItem) -> Void,
        onOpenLink: @escaping (IxListItem) -> Void,
        onCompletionToggle: @escaping (IxListItem) -> Void,
        onCategorize: @escaping (IxListItem, IxListCategory?) -> Void,
        onCreateCategory: @escaping () -> Void,
        onCreateTask: @escaping (IxListItem) -> Void,
        onEdit: @escaping (IxListItem) -> Void,
        onDelete: @escaping (IxListItem) -> Void
    ) {
        self.listId = listId
        self.listColor = listColor
        self.category = category
        self.categories = categories
        self.showCompleted = showCompleted
        self.onClearItemFilter = onClearItemFilter
        self.onCreateItem = onCreateItem

        self.onOpenNotes = onOpenNotes
        self.onOpenLink = onOpenLink
        self.onCompletionToggle = onCompletionToggle
        self.onCategorize = onCategorize
        self.onCreateCategory = onCreateCategory
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

        let sortDescriptor = switch sorting {
        case .name:
            SortDescriptor(\IxListItem.name, order: sortOrder)
        case .creationDate:
            SortDescriptor(\IxListItem.createdAt, order: sortOrder)
//        case .manual:
//            SortDescriptor(\IxListItem.editedAt, order: sortOrder)
        }

        _items = Query(filter: filterPredicate, sort: [SortDescriptor(\IxListItem.completed), sortDescriptor])
    }

    var body: some View {
        List(items) { item in
            ItemRow(
                item: item,
                categories: categories,
                onOpenNotes: onOpenNotes,
                onOpenLink: onOpenLink,
                onCompletionToggle: onCompletionToggle,
                onCategorize: onCategorize,
                onCreateCategory: onCreateCategory,
                onCreateTask: onCreateTask,
                onEdit: onEdit,
                onDelete: onDelete
            ).swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete(item)
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .labelStyle(.iconOnly)
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
                ContentUnavailableView {
                    Label("No items", systemImage: "binoculars")
                        .foregroundStyle(color.contrastColor())
                } description: {
                    Text(items.isEmpty ? "Start adding items to your list now!" : (category == nil ? "There are no uncategorized items" : "There are no items in this category"))
                        .foregroundStyle(color.contrastColor())
                } actions: {
                    Button {
                        onCreateItem()
                    } label: {
                        Label("Create item", systemImage: "plus")
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(color)
    }
}
