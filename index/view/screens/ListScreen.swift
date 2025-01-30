//
//  ListScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/12/24.
//

import SwiftUI
import SwiftData
import AlertToast

struct ListScreen: View {
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    
    private var listId: String
    
    @AppStorage(AppStorageKeys.colors_suggestions) var colorsSuggested: [Color] = AppStorageKeys.Defaults.colors
    
    // MARK: List
    @Query private var lists: [IxList]
    @State private var list: IxList = IxList.loading()
    
    // MARK: Categories and selected category
    @Query private var categories: [IxListCategory]
    @State private var selectedCategoryId: String? = "none"
    @State private var selectedCategory: IxListCategory? = nil
    @State private var nextCategory: IxListCategory? = nil
    @State private var previousCategory: IxListCategory? = nil
    @State private var showItemMovedToNextCategoryToast = false
    @State private var showItemMovedToPreviousCategoryToast = false
    
    // TODO: imrpove ItemsDisplayer performance
//    @State private var debouncedSelectedCategory: IxListCategory? = nil

    private var onCreateNewCategory: Bool { selectedCategoryId == "new" }
    
    @State private var showCategoryEditSheet = false
    
    // MARK: Category creation
    @State private var showCategoryCreationSheet = false
    @State private var newCategoryName = ""
    @State private var newCategoryNamePlaceholder = ""
    @State private var newCategoryColor = Color.accentColor

    // MARK: Selected item
    @State private var selectedItem: IxListItem? = nil
    @State private var showItemEditSheet = false
    @State private var showItemNotePopover = false
    
    // MARK: New item
    @State private var showItemCreationSheet = false
    @State private var newItemName = ""
    @State private var newItemNamePlaceholder = ""
    @State private var newItemLink = ""
    @State private var newItemNote = ""
    @State private var newItemCategory: String? = nil
    
    // MARK: Item filters and sorting
    @AppStorage(AppStorageKeys.item_filter) private var itemFilter = AppStorageKeys.Defaults.item_filter
    @AppStorage(AppStorageKeys.item_sorting) private var itemSorting = AppStorageKeys.Defaults.item_sorting
    @AppStorage(AppStorageKeys.item_reverse_sorting) private var itemReverseSorting = AppStorageKeys.Defaults.item_reverse_sorting
    
    // MARK: Category filters and sorting
    @AppStorage private var showUncategorizedItems: Bool
    @AppStorage(AppStorageKeys.category_sorting) private var categorySorting = AppStorageKeys.Defaults.category_sorting
    @AppStorage(AppStorageKeys.category_reverse_sorting) private var categoryReverseSorting = AppStorageKeys.Defaults.category_reverse_sorting

    init(listId: String) {
        self.listId = listId
        _showUncategorizedItems = AppStorage(wrappedValue: AppStorageKeys.Defaults.show_uncategorized_items, AppStorageKeys.show_uncategorized_items(listId))
        
        // MARK: List query
        var listDescriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.id == listId
            }
        )
        listDescriptor.fetchLimit = 1
        _lists = Query(listDescriptor)
        
        // MARK: Categories query
        let listCategoryDescriptor = FetchDescriptor<IxListCategory>(
            predicate: #Predicate { category in
                category.list_id == listId
            }
        )
        _categories = Query(listCategoryDescriptor)
    }
    
    // MARK: - Local storage savers
    func saveList(_ list: IxList) async throws {
        try context.transaction {
            context.delete(list)
            context.insert(list)
            try context.save()
        }
    }
    
    func saveItem(_ item: IxListItem) async throws {
        try context.transaction {
            context.delete(item)
            context.insert(item)
            try context.save()
        }
    }
    
    func saveCategory(_ category: IxListCategory) async throws {
        try context.transaction {
            context.delete(category)
            context.insert(category)
            try context.save()
        }
    }
    
    // MARK: - Fetchers
    func fetchList() async {
        do {
            list = try await ixApiClient.getList(id: listId)
            try await saveList(list)
        } catch {
            // TODO
        }
    }
    
    func fetchCategories() async {
        do {
            let categories = try await ixApiClient.getListCategories(listId: listId)
            
            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in
                        category.list_id == listId
                    }
                )
                
                categories.forEach { category in
                    context.insert(category)
                }
                
                try context.save()
            }
        } catch {
            
        }
    }
    
    func fetchItems() async {
        do {
            let items = try await ixApiClient.getListItems(listId: listId)
            
            try context.transaction {
                try context.delete(
                    model: IxListItem.self,
                    where: #Predicate { item in
                        item.list_id == listId
                    }
                )
                
                items.forEach { item in
                    context.insert(item)
                }
                
                try context.save()
            }
        } catch {
            
        }
    }
    
    // MARK: - Suggestions
    func fetchColorsSuggestion() async {
        do {
            colorsSuggested = try await ixApiClient.getColorsSuggestion().map { Color(hexString: $0) }
        } catch {
            
        }
    }
    
    func fetchItemTemplateSuggestion() async {
        do {
            let template = try await ixApiClient.getItemTemplateSuggestion()
            newItemNamePlaceholder = template.name
        } catch {
            
        }
    }
    
    func fetchCategoryTemplateSuggestion() async {
        do {
            let template = try await ixApiClient.getCategoryTemplateSuggestion()
            newCategoryNamePlaceholder = template.name
            newCategoryColor = Color(hexString: template.color)
        } catch {
            
        }
    }
    
    // MARK: - Item CRUD
    func createItem(listId: String, name: String, categoryId: String?, link: String?, note: String?) async {
        do {
            let item = try await ixApiClient.createListItem(listId: listId, categoryId: categoryId, name: name, link: link, note: note)
            
            try await saveItem(item)
        } catch {
            print(error)
            // Handle error if needed
        }
    }
    
    func editItem(listId: String, itemId: String, name: String, categoryId: String?, link: String?, note: String?) async {
        do {
            let item = try await ixApiClient.updateListItem(listId: listId, itemId: itemId, name: name, categoryId: categoryId, link: link, note: note)
            
            try await saveItem(item)
        } catch {
            print(error)
            // Handle error if needed
        }
    }
    
    func setItemCompletion(listId: String, itemId: String, completed: Bool) async {
        do {
            let item = try await ixApiClient.setListItemCompletion(listId: listId, itemId: itemId, completed: completed)
            
            try await saveItem(item)
        } catch {
            
        }
    }
    
    func deleteItem(listId: String, itemId: String) async {
        do {
            try await ixApiClient.deleteListItem(listId: listId, itemId: itemId)
            
            try context.delete(model: IxListItem.self, where: #Predicate { item in item.id == itemId })
        } catch IxApiClientError.NotFound {
            do { try context.delete(model: IxListItem.self, where: #Predicate { item in item.id == itemId }) } catch {}
        } catch {
            
        }
    }
    
    // MARK: - Category CRUD
    func createCategory(listId: String, name: String, color: Color) async {
        do {
            let category = try await ixApiClient.createCategory(listId: listId, name: name, color: color.hexString())
            
            try await saveCategory(category)
            
            withAnimation {
                selectedCategoryId = category.id
            }
        } catch {
            
        }
    }
    
    func editCategory(listId: String, categoryId: String, name: String, color: Color) async {
        do {
            let category = try await ixApiClient.updateListCategory(listId: listId, categoryId: categoryId, name: name, color: color.hexString())
            
            try await saveCategory(category)
        } catch {
            
        }
    }
    
    func deleteCategory(listId: String, categoryId: String) async {
        do {
            try await ixApiClient.deleteListCategory(listId: listId, categoryId: categoryId)
            
            try context.delete(model: IxListCategory.self, where: #Predicate { category in category.id == categoryId })
        } catch IxApiClientError.NotFound {
            do { try context.delete(model: IxListCategory.self, where: #Predicate { category in category.id == categoryId }) } catch {}
        } catch {
            
        }
    }
    
    var body: some View {
        ScreenContent
            .sheet(
                isPresented: $showItemCreationSheet,
                content: {
                    ItemFormSheet(
                        showSheet: $showItemCreationSheet,
                        name: "",
                        category: selectedCategory,
                        link: nil,
                        note: nil,
                        categories: categories,
                        namePlaceholder: newItemNamePlaceholder
                    ) { name, category, link, note in
                        Task {
                            await createItem(listId: listId, name: name, categoryId: category?.id, link: link, note: note)
                        }
                    }
            })
            .sheet(
                isPresented: $showItemEditSheet,
                content: {
                    ItemFormSheet(
                        showSheet: $showItemEditSheet,
                        name: selectedItem?.name ?? "",
                        category: categories.first { c in c.id == selectedItem?.category_id
                        },
                        link: selectedItem?.link,
                        note: selectedItem?.note,
                        categories: categories,
                        namePlaceholder: newItemNamePlaceholder) { name, category, link, note in
                            Task {
                                if let selectedItem = selectedItem {
                                    await editItem(listId: listId, itemId: selectedItem.id, name: name, categoryId: category?.id, link: link, note: note)
                                }
                            }
                        }
            })
            .sheet(
                isPresented: $showCategoryCreationSheet,
                content: {
                    CategoryFormSheet(
                        showSheet: $showCategoryCreationSheet,
                        name: newCategoryName,
                        color: newCategoryColor,
                        namePlaceholder: newCategoryNamePlaceholder,
                        colors: colorsSuggested
                    ) { name, color in
                        Task {
                            await createCategory(listId: listId, name: name, color: color)
                        }
                    }
            })
            .sheet(
                isPresented: $showCategoryEditSheet,
                content: {
                    CategoryFormSheet(
                        showSheet: $showCategoryEditSheet,
                        name: selectedCategory?.name ?? "",
                        color: Color(hexString: selectedCategory?.color ?? Color.accentColor.hexString()),
                        namePlaceholder: newCategoryNamePlaceholder,
                        colors: colorsSuggested
                    ) { name, color in
                        Task {
                            if let category = selectedCategory {
                                await editCategory(listId: listId, categoryId: category.id, name: name, color: color)
                            }
                        }
                    }
            })
            .sheet(isPresented: $showItemNotePopover) {
                NavigationView {
                    ScrollView(showsIndicators: false) {
                        Text(selectedItem?.note ?? "This item has no notes in it")
                            .navigationTitle("Notes")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") {
                                        showItemNotePopover = false
                                    }
                                }
                            }
                    }.padding()
                }.presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
            }
            .navigationTitle(list.name)
            .toolbar {
                // MARK: - Toolbar
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Picker(selection: $itemFilter) {
                                ForEach(ItemFilter.allCases) { filter in
                                    Text(filter.rawValue)
                                        .tag(filter)
                                }
                            } label: {
                                Label("Items filter", systemImage: "line.3.horizontal.decrease")
                            }.pickerStyle(.menu)
                            
                            Picker(selection: $itemSorting) {
                                ForEach(ItemSorting.allCases) { sort in
                                    Text(sort.rawValue)
                                        .tag(sort)
                                }
                            } label: {
                                Label("Items sorting", systemImage: "arrow.up.arrow.down")
                            }.pickerStyle(.menu)
                            
                            Toggle("Items reverse sorting", isOn: $itemReverseSorting)
                        }
                        
                        Section {
                            Toggle("Show default category", isOn: $showUncategorizedItems)
                            
                            Picker(selection: $categorySorting) {
                                ForEach(CategorySorting.allCases) { sort in
                                    Text(sort.rawValue)
                                        .tag(sort)
                                }
                            } label: {
                                Label("Categories sorting", systemImage: "arrow.up.arrow.down")
                            }.pickerStyle(.menu)
                            
                            Toggle("Categories reverse sorting", isOn: $categoryReverseSorting)
                        }
                        
                        if selectedCategoryId != "none", !onCreateNewCategory, let selectedCategoryId = selectedCategoryId {
                            Section {
                                Button("Edit category", systemImage: "square.and.pencil") {
                                    showCategoryEditSheet = true
                                }
                                
                                Menu {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        Task {
                                            await deleteCategory(listId: listId, categoryId: selectedCategoryId)
                                        }
                                    }
                                    
                                    Button("Cancel", role: .cancel) {}
                                } label: {
                                    Label("Delete category", systemImage: "trash")
                                }
                            }
                        }
                    
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .toast(isPresenting: $showItemMovedToNextCategoryToast) {
                // TODO: [UI] background color and toast style
                AlertToast(displayMode: .hud, type: .regular, title: nil, subTitle: "Item moved to next category!")
            }
            .toast(isPresenting: $showItemMovedToPreviousCategoryToast) {
                AlertToast(displayMode: .hud, type: .regular, title: nil, subTitle: "Item moved to previous category!")
            }
            .onAppear {
                if SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.list(listId)) {
                    Task {
                        await fetchList()
                    }
                    Task {
                        await fetchCategories()
                    }
                    Task {
                        await fetchItems()
                    }
                    
                    Task {
                        let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.SUGGESTION_COLORS)
                        
                        if shouldSync {
                            await fetchColorsSuggestion()
                        }
                    }
                }
            }
            .onChange(of: showItemCreationSheet, initial: true) { _, new in
                if new {
                    Task {
                        await fetchItemTemplateSuggestion()
                    }
                }
            }
            .onChange(of: showCategoryCreationSheet, initial: true) { _, new in
                if new {
                    Task {
                        await fetchCategoryTemplateSuggestion()
                    }
                }
            }
            .onChange(of: showCategoryEditSheet, initial: true) { _, new in
                if new {
                    Task {
                        await fetchCategoryTemplateSuggestion()
                    }
                }
            }
            .onChange(of: lists) { _, newLists in
                guard let newList = newLists.first else {
                    navigationManager.pop()
                    return
                }
                
                list = newList
            }
    }
    
    private var ScreenContent: some View {
        VStack {
            ItemsDisplayer(
                listId: listId,
                category: selectedCategory,
                itemFilter: itemFilter,
                itemSorting: itemSorting,
                itemReverseSorting: itemReverseSorting,
                onClearItemFilter: {
                    itemFilter = .uncompleted
                },
                onNewCategory: onCreateNewCategory,
                onCreateItem: {
                    showItemCreationSheet = true
                },
                onCreateCategory: {
                    showCategoryCreationSheet = true
                },
                onOpenNotes: { item in
                    selectedItem = item
                    showItemNotePopover = true
                },
                onOpenLink: { item, link in
                    if let url = URL(string: link) {
                        openURL(url)
                    }
                },
                onCompletionChange: { item, completed in
                    Task {
                        await setItemCompletion(listId: item.list_id, itemId: item.id, completed: completed)
                    }
                },
                onCreateTask: { item in
                    // TODO
                },
                onEdit: { item in
                    selectedItem = item
                    showItemEditSheet = true
                },
                onDelete: { item in
                    Task {
                        await deleteItem(listId: listId, itemId: item.id)
                    }
                },
                onMoveToPreviousCategory: { item, completionAction in
                    if previousCategory == nil && item.category_id != nil {
                        Task {
                            await editItem(listId: listId, itemId: item.id, name: item.name, categoryId: nil, link: item.link, note: item.note)
                            showItemMovedToPreviousCategoryToast = true
                            completionAction()
                        }
                    } else if let previousCategory = previousCategory {
                        Task {
                            await editItem(listId: listId, itemId: item.id, name: item.name, categoryId: previousCategory.id, link: item.link, note: item.note)
                            showItemMovedToPreviousCategoryToast = true
                            completionAction()
                        }
                    }
                },
                onMoveToNextCategory: { item, completionAction in
                    if let nextCategory = nextCategory {
                        Task {
                            await editItem(listId: listId, itemId: item.id, name: item.name, categoryId: nextCategory.id, link: item.link, note: item.note)
                            showItemMovedToNextCategoryToast = true
                            completionAction()
                        }
                    }
                }
            )
                .padding(.horizontal)
            
            VStack {
                CategorySelector(
                    listId: listId,
                    selectedCategoryId: $selectedCategoryId,
                    selectedCategory: $selectedCategory,
                    previousCategory: $previousCategory,
                    nextCategory: $nextCategory,
                    showUncategorizedItems: showUncategorizedItems,
                    categorySorting: categorySorting,
                    categoryReverseSorting: categoryReverseSorting,
                    onSelectedTap: { categoryId in
                        showItemCreationSheet = true
                    },
                    onHideUncategorized: {
                        showUncategorizedItems = false
                    },
                    onNewCategoryTap: {
                        showCategoryCreationSheet = true
                    },
                    onEdit: { category in
                        selectedCategoryId = category.id
                        showCategoryEditSheet = true
                    },
                    onDelete: { category in
                        Task {
                            await deleteCategory(listId: listId, categoryId: category.id)
                            
                            if (selectedCategoryId == category.id) {
                                withAnimation {
                                    selectedCategoryId = previousCategory?.id ?? (showUncategorizedItems ? "none" : "new")
                                }
                            }
                        }
                    }
                )
                    .frame(height: CategoryUIDefaults.height + 48)
                    
                
                Text(onCreateNewCategory ? "Create category" : (selectedCategory?.name ?? "Create item"))
            }
        }
    }
}

#Preview {
    ListScreen(listId: "123")
        .environmentObject(IxApiClient())
        .environmentObject(NavigationManager())
}
