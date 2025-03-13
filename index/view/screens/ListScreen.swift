//
//  ListScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/12/24.
//

import SwiftUI
import SwiftData

struct ListScreen: View {
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    
    private var listId: String
    
    @AppStorage(AppStorageKeys.colors_suggestions) var colorsSuggested: [Color] = AppStorageKeys.Defaults.colors
    
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
    
    // TODO: imrpove ItemsDisplayer performance
//    @State private var debouncedSelectedCategory: IxListCategory? = nil

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
    
    // MARK: Tas
    @State private var showTaskCreationSheet = false
    
    // MARK: Item filters and sorting
    @AppStorage(AppStorageKeys.item_filter) private var itemFilter = AppStorageKeys.Defaults.item_filter
    @AppStorage(AppStorageKeys.item_sorting) private var itemSorting = AppStorageKeys.Defaults.item_sorting
    @AppStorage(AppStorageKeys.item_reverse_sorting) private var itemReverseSorting = AppStorageKeys.Defaults.item_reverse_sorting
    
    // MARK: Category filters and sorting
    @AppStorage private var hideDefaultCategory: Bool
    @AppStorage(AppStorageKeys.category_sorting) private var categorySorting = AppStorageKeys.Defaults.category_sorting
    @AppStorage(AppStorageKeys.category_reverse_sorting) private var categoryReverseSorting = AppStorageKeys.Defaults.category_reverse_sorting

    init(listId: String) {
        self.listId = listId
        _hideDefaultCategory = AppStorage(wrappedValue: AppStorageKeys.Defaults.hide_default_category, AppStorageKeys.hide_default_category(listId))
        
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
                        category.list_id == listId
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
                        item.list_id == listId
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
        } catch IxApiClientError.NotFound {
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
            let category = try await ixApiClient.createCategory(listId: listId, name: name, color: color.hexString())
            
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
            let category = try await ixApiClient.updateListCategory(listId: listId, categoryId: categoryId, name: name, color: color.hexString())
            
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
        } catch IxApiClientError.NotFound {
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
        } catch IxApiClientError.ProRequired(let proFeature) {
            // TODO: Show pro sheet with a global toggle
        } catch {
            errorService.insert(.localizedError(title: "Error creating task", error: error))
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
                content: { [selectedItem] in
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
                content: { [selectedCategory] in
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
            .sheet(isPresented: $showItemNotePopover) { [selectedItem] in
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
            .sheet(
                isPresented: $showTaskCreationSheet,
                content: { [selectedItem] in
                    TaskFormSheet(
                        showSheet: $showTaskCreationSheet,
                        name: selectedItem?.name ?? "",
                        description: selectedItem?.note,
                        priority: nil,
                        dueDate: nil,
                        rrule: nil,
                        reminders: [],
                        itemId: nil,
                        subtasks: [],
                        namePlaceholder: "Task name"
                    ) { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
                        Task {
                            await createTask(name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
                        }
                    }
                }
            )
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
                            Toggle("Hide default category", isOn: $hideDefaultCategory)
                            
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
                    
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            showItemCreationSheet = true
                        } label: {
                            Label("Create item", systemImage: "plus.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .fontWeight(.semibold)
                                .foregroundStyle(selectedCategory?.color.toColor(fallback: .accentColor) ?? Color.accentColor)
                        }
                        
                        Spacer()
                        
                        CategoryPicker(
                            listId: listId,
                            selectedCategory: $selectedCategory,
                            categorySorting: categorySorting,
                            categoryReverseSorting: categoryReverseSorting,
                            hideDefaultCategory: hideDefaultCategory) {
                                showCategoryCreationSheet = true
                            } onEdit: { category in
                                selectedCategory = category
                                showCategoryEditSheet = true
                            } onDelete: { category in
                                Task {
                                    await deleteCategory(listId: listId, categoryId: category.id)
                                }
                            }
                    }.padding(.top)
                }
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
        ItemsList(
            listId: listId,
            category: selectedCategory,
            itemFilter: itemFilter,
            itemSorting: itemSorting,
            itemReverseSorting: itemReverseSorting) {
                itemFilter = .uncompleted
            } onCreateItem: {
                showItemCreationSheet = true
            } onOpenNotes: { item in
                selectedItem = item
                showItemNotePopover = true
            } onOpenLink: { _, link in
                var urlString = link
                if !urlString.starts(with: "http") {
                    urlString = "https://\(urlString)"
                }
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            } onCompletionChange: { item, completion in
                Task {
                    await setItemCompletion(listId: item.list_id, itemId: item.id, completed: completion)
                }
            } onCreateTask: { item in
                selectedItem = item
                showTaskCreationSheet = true
            } onEdit: { item in
                selectedItem = item
                showItemEditSheet = true
            } onDelete: { item in
                Task {
                    await deleteItem(listId: listId, itemId: item.id)
                }
            }
    }
}

#Preview {
    ListScreen(listId: "123")
        .environmentObject(IxApiClient())
        .environmentObject(NavigationManager())
        .environmentObject(ErrorStateService())
}
