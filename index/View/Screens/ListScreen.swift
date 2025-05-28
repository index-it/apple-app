//
//  ListScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/12/24.
//

import SwiftUI
import SwiftData
import WidgetKit
import IxCoreKit

struct ListScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var errorService: ErrorStateService
    
    @State private var showPaywall = false
    
    private var listId: String
    
    // MARK: List
    @Query private var lists: [IxList]
    @State private var list: IxList = IxList.loading()
    
    // MARK: Categories and selected category
    @Query private var categories: [IxListCategory]
    @State private var selectedCategory: IxListCategory? = nil
    @State private var nextCategory: IxListCategory? = nil
    @State private var previousCategory: IxListCategory? = nil
    @State private var showItemMovedToNextCategoryToast = false
    @State private var showItemMovedToPreviousCategoryToast = false
    
    @State private var isEditingCategory = false
    
    // MARK: Category creation
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryNamePlaceholder = "Category name"
    @State private var newCategoryColor = Color.accentColor
    
    // MARK: Selected item
    @State private var selectedItem: IxListItem? = nil
    @State private var isEditingItem = false
    @State private var showItemNotePopover = false
    
    // MARK: New item
    @State private var isAddingItem = false
    @State private var newItemName = ""
    @State private var newItemNamePlaceholder = "Name"
    @State private var newItemLink = ""
    @State private var newItemNote = ""
    @State private var newItemCategory: String? = nil
    
    // MARK: Tas
    @State private var showTaskCreationSheet = false
    
    // MARK: Item filters and sorting
    @AppStorage private var showCompletedItems: Bool
    @AppStorage private var itemSorting: ItemsSorting
    @AppStorage private var itemsSortOrder: SortOrder
    
    // MARK: Category filters and sorting
    @AppStorage private var hideUncategorized: Bool
    @AppStorage private var categoriesSorting: CategoriesSorting
    @AppStorage private var categoriesSortOrder: SortOrder
    
    private var contentColor: Color {
        guard let selectedCategory = selectedCategory else {
            return list.color.toColor()
        }
        
        return selectedCategory.color.toColor()
    }
    
    init(listId: String) {
        self.listId = listId
        
        // MARK: AppStorage init
        _showCompletedItems = AppStorage(wrappedValue: AppStorageKeys.Defaults.itemsShowCompleted, AppStorageKeys.Items.show_completed(listId))
        _itemSorting = AppStorage(wrappedValue: AppStorageKeys.Defaults.itemsSorting, AppStorageKeys.Items.sorting(listId))
        _itemsSortOrder = AppStorage(wrappedValue: AppStorageKeys.Defaults.itemsSortOrder, AppStorageKeys.Items.sortOrder(listId))
        
        _hideUncategorized = AppStorage(wrappedValue: AppStorageKeys.Defaults.hideUncategorized, AppStorageKeys.Categories.hideUncategorized(listId))
        _categoriesSorting = AppStorage(wrappedValue: AppStorageKeys.Defaults.categoriesSorting, AppStorageKeys.Categories.sorting(listId))
        _categoriesSortOrder = AppStorage(wrappedValue: AppStorageKeys.Defaults.categoriesSortOrder, AppStorageKeys.Categories.sortOrder(listId))
        
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
                category.listId == listId
            }
        )
        _categories = Query(listCategoryDescriptor)
    }
    
    // MARK: - Local storage savers
    func saveList(_ list: IxList) async throws {
        try context.transaction {
            context.insert(list)
        }
    }
    
    func saveItem(_ item: IxListItem) async throws {
        try context.transaction {
            context.insert(item)
        }
    }
    
    func saveCategory(_ category: IxListCategory) async throws {
        try context.transaction {
            context.insert(category)
        }
    }
    
    // MARK: - Fetchers
    func fetchList() async {
        do {
            list = try await ixApiClient.getList(id: listId)
            try await saveList(list)
        } catch {
            errorService.insert(.localizedError(title: "Error loading list", error: error))
        }
    }
    
    func fetchCategories() async {
        do {
            let categories = try await ixApiClient.getListCategories(listId: listId)
            
            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in
                        category.listId == listId
                    }
                )
                
                categories.forEach { category in
                    context.insert(category)
                }
            }
        } catch {
            errorService.insert(.localizedError(title: "Error loading categories", error: error))
        }
    }
    
    func fetchItems() async {
        do {
            let items = try await ixApiClient.getListItems(listId: listId)
            
            try context.transaction {
                try context.delete(
                    model: IxListItem.self,
                    where: #Predicate { item in
                        item.listId == listId
                    }
                )
                
                items.forEach { item in
                    context.insert(item)
                }
            }
        } catch {
            errorService.insert(.localizedError(title: "Error loading list items", error: error))
        }
    }
    
    // MARK: - Item CRUD
    func createItem(listId: String, name: String, categoryId: String?, link: String?, note: String?) async {
        do {
            let item = try await ixApiClient.createListItem(listId: listId, categoryId: categoryId, name: name, link: link, note: note)
            
            try await saveItem(item)
        } catch {
            errorService.insert(.localizedError(title: "Error creating item", error: error))
        }
    }
    
    func editItem(listId: String, itemId: String, name: String, categoryId: String?, link: String?, note: String?) async {
        do {
            let item = try await ixApiClient.updateListItem(listId: listId, itemId: itemId, name: name, categoryId: categoryId, link: link, note: note)
            
            try await saveItem(item)
        } catch {
            errorService.insert(.localizedError(title: "Error editing item", error: error))
        }
    }
    
    func setItemCompletion(listId: String, itemId: String, completed: Bool) async {
        do {
            let item = try await ixApiClient.setListItemCompletion(listId: listId, itemId: itemId, completed: completed)
            
            try await saveItem(item)
        } catch {
            errorService.insert(.localizedError(title: "Error \(completed ? "completing" : "un-completing") item", error: error))
        }
    }
    
    func deleteItem(listId: String, itemId: String) async {
        do {
            try await ixApiClient.deleteListItem(listId: listId, itemId: itemId)
            
            try context.transaction {
                try context.delete(model: IxListItem.self, where: #Predicate { item in item.id == itemId })
            }
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(model: IxListItem.self, where: #Predicate { item in item.id == itemId })
                }
            } catch {}
        } catch {
            errorService.insert(.localizedError(title: "Error deleting item", error: error))
        }
    }
    
    // MARK: - Category CRUD
    func createCategory(listId: String, name: String, color: Color) async {
        do {
            let category = try await ixApiClient.createCategory(listId: listId, name: name, color: color.hexString)
            
            try await saveCategory(category)
            
            withAnimation {
                selectedCategory = category
            }
        } catch {
            errorService.insert(.localizedError(title: "Error creating category", error: error))
        }
    }
    
    func editCategory(listId: String, categoryId: String, name: String, color: Color) async {
        do {
            let category = try await ixApiClient.updateListCategory(listId: listId, categoryId: categoryId, name: name, color: color.hexString)
            
            try await saveCategory(category)
        } catch {
            errorService.insert(.localizedError(title: "Error editing category", error: error))
        }
    }
    
    func deleteCategory(listId: String, categoryId: String) async {
        do {
            try await ixApiClient.deleteListCategory(listId: listId, categoryId: categoryId)
            
            try context.transaction {
                try context.delete(model: IxListCategory.self, where: #Predicate { category in category.id == categoryId })
            }
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(model: IxListCategory.self, where: #Predicate { category in category.id == categoryId })
                }
            } catch {}
        } catch {
            errorService.insert(.localizedError(title: "Error deleting category", error: error))
        }
        
        if selectedCategory?.id == categoryId {
            selectedCategory = categories.first
        }
    }
    
    // MARK: Task
    func createTask(
        name: String,
        description: String?,
        dueDate: Date?,
        rrule: String?,
        reminders: [IxTaskReminder],
        subtasks: [IxSubTask],
        priority: Int?,
        itemId: String?
    ) async {
        do {
            let task = try await ixApiClient.createTask(name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
            
            try context.transaction {
                context.insert(task)
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        } catch IxApiClientError.proRequired(_) {
            showPaywall = true
        } catch {
            errorService.insert(.localizedError(title: "Error creating task", error: error))
        }
    }
    
    var body: some View {
        ScreenContent
            .sheet(
                isPresented: $isAddingItem,
                content: {
                    ItemEditor(
                        isPresented: $isAddingItem,
                        addingNew: true,
                        name: "",
                        categoryId: selectedCategory?.id,
                        link: nil,
                        note: nil,
                        categories: categories,
                    ) { name, categoryId, link, note in
                        Task {
                            await createItem(listId: listId, name: name, categoryId: categoryId, link: link, note: note)
                        }
                    }
                })
            .sheet(
                isPresented: $isEditingItem,
                content: { [selectedItem] in
                    ItemEditor(
                        isPresented: $isEditingItem,
                        addingNew: false,
                        name: selectedItem?.name ?? "",
                        categoryId: selectedItem?.categoryId,
                        link: selectedItem?.link,
                        note: selectedItem?.note,
                        categories: categories
                    ) { name, categoryId, link, note in
                        Task {
                            if let selectedItem = selectedItem {
                                await editItem(listId: listId, itemId: selectedItem.id, name: name, categoryId: categoryId, link: link, note: note)
                            }
                        }
                    }
                })
            .sheet(
                isPresented: $isAddingCategory,
                content: {
                    CategoryEditor(
                        isPresented: $isAddingCategory
                    ) { name, color in
                        Task {
                            await createCategory(listId: listId, name: name, color: color)
                        }
                    }
                })
            .sheet(
                isPresented: $isEditingCategory,
                content: { [selectedCategory] in
                    CategoryEditor(
                        isPresented: $isEditingCategory,
                        addingNew: false,
                        name: selectedCategory?.name ?? "",
                        color: selectedCategory?.color.toColorOrNil()
                    ) { name, color in
                        Task {
                            if let category = selectedCategory {
                                await editCategory(listId: listId, categoryId: category.id, name: name, color: color)
                            }
                        }
                    }
                })
        //            .sheet(isPresented: $showItemNotePopover) { [selectedItem] in
        //                NavigationView {
        //                    ScrollView(showsIndicators: false) {
        //                        Text(selectedItem?.note ?? "This item has no notes in it")
        //                            .navigationTitle("Notes")
        //                            .navigationBarTitleDisplayMode(.inline)
        //                            .toolbar {
        //                                ToolbarItem(placement: .topBarTrailing) {
        //                                    Button("Done") {
        //                                        showItemNotePopover = false
        //                                    }
        //                                }
        //                            }
        //                    }.padding()
        //                }.presentationDetents([.medium, .large])
        //                    .presentationDragIndicator(.hidden)
        //            }
        //            .sheet(
        //                isPresented: $showTaskCreationSheet,
        //                content: { [selectedItem] in
        //                    TaskFormSheet(
        //                        showSheet: $showTaskCreationSheet,
        //                        name: selectedItem?.name ?? "",
        //                        description: selectedItem?.note,
        //                        priority: nil,
        //                        dueDate: nil,
        //                        rrule: nil,
        //                        reminders: [],
        //                        itemId: selectedItem?.id,
        //                        subtasks: [],
        //                        namePlaceholder: "Task name"
        //                    ) { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
        //                        Task {
        //                            await createTask(name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
        //                        }
        //                    }
        //                }
        //            )
            .navigationTitle(list.name)
            .paywallCover(isPresented: $showPaywall)
            .toolbar {
                // MARK: - Toolbar
                ToolbarItem(placement: .topBarTrailing) {
                    //                    Menu {
                    //                        Section {
                    //                            Toggle("Show completed", isOn: Binding(
                    //                                get: {
                    //                                    showCompletedItems
                    //                                }, set: { newValue in
                    //                                    showCompletedItems = newValue
                    //                                }
                    //                            ))
                    //
                    //                            Picker(selection: $itemSorting) {
                    //                                ForEach(ItemsSorting.allCases) { sort in
                    //                                    Text(sort.label)
                    //                                        .tag(sort)
                    //                                }
                    //                            } label: {
                    //                                Label("Items sorting", systemImage: "arrow.up.arrow.down")
                    //                            }.pickerStyle(.menu)
                    //
                    //                            Toggle("Items reverse sorting", isOn: $item)
                    //                        }
                    //
                    //                        Section {
                    //                            Toggle("Hide default category", isOn: $hideDefaultCategory)
                    //
                    //                            Picker(selection: $categorySorting) {
                    //                                ForEach(CategorySorting.allCases) { sort in
                    //                                    Text(sort.rawValue)
                    //                                        .tag(sort)
                    //                                }
                    //                            } label: {
                    //                                Label("Categories sorting", systemImage: "arrow.up.arrow.down")
                    //                            }.pickerStyle(.menu)
                    //
                    //                            Toggle("Categories reverse sorting", isOn: $categoryReverseSorting)
                    //                        }
                    //
                    //                    } label: {
                    //                        Label("Options", systemImage: "ellipsis.circle")
                    //                            .labelStyle(.iconOnly)
                    //                    }
                    //                }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            isAddingItem = true
                        } label: {
                            Label("Create item", systemImage: "plus.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .fontWeight(.semibold)
                                .foregroundStyle(contentColor)
                        }
                        
                        Spacer()
                        
                        CategoryPicker(
                            listId: listId,
                            selectedCategory: $selectedCategory,
                            sorting: categoriesSorting,
                            sortOrder: categoriesSortOrder,
                            hideUncategorized: hideUncategorized
                        ) {
                            isAddingCategory = true
                        } onEdit: { category in
                            selectedCategory = category
                            isEditingCategory = true
                        } onDelete: { category in
                            Task {
                                await deleteCategory(listId: listId, categoryId: category.id)
                            }
                        }
                    }.padding(.top)
                }
            }
            .onAppear {
                Task {
                    if await SyncRegister.shared.hasExpired(SyncResource.list(listId)) {
                        Task {
                            await fetchList()
                        }
                        Task {
                            await fetchCategories()
                        }
                        Task {
                            await fetchItems()
                        }
                    }
                }
            }
            .onChange(of: lists, initial: true) { _, newLists in
                guard let newList = newLists.first else {
                    navigationManager.pop()
                    return
                }
                
                list = newList
            }
    }
    
    var ScreenContent: some View {
        ItemsList(
            listId: listId,
            listColor: contentColor,
            category: selectedCategory,
            showCompleted: showCompletedItems,
            sorting: itemSorting,
            sortOrder: itemsSortOrder) {
                showCompletedItems = false
            } onCreateItem: {
                isAddingItem = true
            } onOpenNotes: { item in
                selectedItem = item
                showItemNotePopover = true
            } onOpenLink: { item in
                guard let link = item.link else { return }
                
                var urlString = link
                if !urlString.starts(with: "http") {
                    urlString = "https://\(urlString)"
                }
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            } onCompletionToggle: { item in
                Task {
                    await setItemCompletion(listId: item.listId, itemId: item.id, completed: !item.completed)
                }
            } onCreateTask: { item in
                selectedItem = item
                showTaskCreationSheet = true
            } onEdit: { item in
                selectedItem = item
                isEditingItem = true
            } onDelete: { item in
                Task {
                    await deleteItem(listId: listId, itemId: item.id)
                }
            }
    }
}
