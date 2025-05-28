//
//  CategorySelector.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import SwiftUI
import SwiftData
import IxCoreKit

struct CategoryPicker: View {
    @Binding private var selectedCategory: IxListCategory?
    
    @Query private var categories: [IxListCategory]
    
    private var hideUncategorized: Bool
    private var onCreate: () -> Void
    private var onEdit: (_ category: IxListCategory) -> Void
    private var onDelete: (_ category: IxListCategory) -> Void
    
    init(
        listId: String,
        selectedCategory: Binding<IxListCategory?>,
        sorting: CategoriesSorting,
        sortOrder: SortOrder,
        hideUncategorized: Bool,
        onCreate: @escaping () -> Void,
        onEdit: @escaping (_ category: IxListCategory) -> Void,
        onDelete: @escaping (_ category: IxListCategory) -> Void
    ) {
        self._selectedCategory = selectedCategory
        self.hideUncategorized = hideUncategorized
        self.onCreate = onCreate
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let filterPredicate = #Predicate<IxListCategory> { category in
            category.listId == listId
        }
        
        // TODO: Manual
        let sortDescriptor = switch sorting {
        case .name:
            SortDescriptor(\IxListCategory.name, order: sortOrder)
        case .creationDate:
            SortDescriptor(\IxListCategory.createdAt, order: sortOrder)
        case .manual:
            SortDescriptor(\IxListCategory.editedAt, order: sortOrder)
        }
        
        _categories = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    var body: some View {
        Menu {
            Section {
                if let selectedCategory = selectedCategory {
                    Menu {
                        Button("Cancel", role: .cancel) {}
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onDelete(selectedCategory)
                        }
                    } label: {
                        Label("Delete category", systemImage: "trash")
                    }
                    
                    Button("Edit category", systemImage: "square.and.pencil") {
                        onEdit(selectedCategory)
                    }
                }
                
                Button("Create category", systemImage: "plus") {
                    onCreate()
                }
            }
            
            ForEach(categories) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        // TODO: Category color circle
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                        }
                        
                        Text(category.name)
                    }
                }
            }
            
            if !hideUncategorized {
                Button {
                    selectedCategory = nil
                } label: {
                    HStack {
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                        }
                        
                        Text("Uncategorized")
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedCategory?.name.prefix(20) ?? "Default")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(UIColor.secondarySystemFill.toColor())
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onChange(of: categories, initial: true) { _, newCategories in
            if hideUncategorized && selectedCategory == nil {
                selectedCategory = newCategories.first
            }
        }
        .onChange(of: hideUncategorized) { _, newValue in
            if newValue && selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }
}

