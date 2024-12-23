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
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    
    private var listId: String
    
    @State private var colorsSuggested: [Color] = []
    
    @Query private var lists: [IxList]
    @State private var list: IxList = IxList.loading()
    
    @Query private var categories: [IxListCategory]
    @State private var selectedCategoryId: String? = "none"
    private var onCreateNewCategory: Bool {
        selectedCategoryId == "new"
    }
    private var selectedCategory: IxListCategory? {
        if selectedCategoryId == "none" || selectedCategoryId == "new" {
            nil
        } else {
            categories.first { $0.id == selectedCategoryId }
        }
    }
    
    @State private var selectedItem: IxListItem? = nil
    @State private var showItemEditSheet = false
    
    @State private var showItemCreationSheet = false
    @State private var newItemName = ""
    @State private var newItemNamePlaceholder = ""
    @State private var newItemLink = ""
    @State private var newItemCategory: String? = nil
    
    @State private var showCategoryEditSheet = false
    
    @State private var showCategoryCreationSheet = false
    @State private var newCategoryName = ""
    @State private var newCategoryNamePlaceholder = ""
    @State private var newCategoryColor = Color.accentColor
    
    
    init(listId: String) {
        self.listId = listId
        
        // List query
        var listDescriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.id == listId
            }
        )
        listDescriptor.fetchLimit = 1
        _lists = Query(listDescriptor)
        
        // Categories query
        let listCategoryDescriptor = FetchDescriptor<IxListCategory>(
            predicate: #Predicate { category in
                category.list_id == listId
            }
        )
        _categories = Query(listCategoryDescriptor)
    }
    
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
    
    func fetchColorsSuggestion() async {
        do {
            colorsSuggested = try await ixApiClient.getColorsSuggestion().map { Color(hexString: $0) }
            
            self.colorsSuggested = colorsSuggested
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
    
    func createItem(listId: String, name: String, categoryId: String?, link: String?) async {
        do {
            let item = try await ixApiClient.createListItem(listId: listId, categoryId: categoryId, name: name, link: link)
            
            try await saveItem(item)
        } catch {
            print(error)
            // Handle error if needed
        }
    }
    
    func editItem(listId: String, itemId: String, name: String, categoryId: String?, link: String?) async {
        do {
            let item = try await ixApiClient.updateListItem(listId: listId, itemId: itemId, name: name, categoryId: categoryId, link: link)
            
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
    
    func createCategory(listId: String, name: String, color: Color) async {
        do {
            let category = try await ixApiClient.createCategory(listId: listId, name: name, color: color.hexString())
            
            try await saveCategory(category)
        } catch {
            
        }
    }
    
    func editCategory(listId: String, categoryId: String, name: String, color: String) async {
        do {
            let category = try await ixApiClient.updateListCategory(listId: listId, categoryId: categoryId, name: name, color: color)
            
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
                        categories: categories,
                        namePlaceholder: newItemNamePlaceholder
                    ) { name, category, link in
                        Task {
                            await createItem(listId: listId, name: name, categoryId: category?.id, link: link)
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
                        categories: categories,
                        namePlaceholder: newItemNamePlaceholder) { name, category, link in
                            Task {
                                if let selectedItem = selectedItem {
                                    await editItem(listId: listId, itemId: selectedItem.id, name: name, categoryId: category?.id, link: link)
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
//            .sheet(
//                isPresented: $showCategoryEditSheet,
//                content: {
//                    CategoryFormSheet(
//                        showSheet: $showCategoryEditSheet,
//                        name: selectedCategory?.name ?? "",
//                        color: selectedCategory.color ?? Color.accentColor,
//                        namePlaceholder: newCategoryNamePlaceholder,
//                        colors: $colorsSuggested
//                    ) { name, color in
//                        Task {
//                            if let category = selectedCategory {
//                                await editCategory(listId: listId, categoryId: category.id, name: name, color: color)
//                            }
//                        }
//                    }
//            })
            .navigationTitle(list.name)
            .onAppear {
                if SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.list(listId)) {
                    Task {
                        await fetchList()
                    }
                    Task {
                        await fetchCategories()
//                        selectedCategoryId = categories.first?.id
                    }
                    Task {
                        await fetchItems()
                    }
                    
                    Task {
                        let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.SUGGESTION_COLORS)
                        
                        // TODO: Save in AppStorage
                        await fetchColorsSuggestion()
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
                withCompleted: true,
                onNewCategory: onCreateNewCategory,
                onCreateItem: {
                    showItemCreationSheet = true
                },
                onCreateCategory: {
                    showCategoryCreationSheet = true
                },
                onOpen: { item in
                    // TODO
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
                }
            )
                .padding(.horizontal)
            
            VStack {
                CategorySelector(
                    categories: categories,
                    selectedCategoryId: $selectedCategoryId,
                    onSelectedTap: { categoryId in
                        showItemCreationSheet = true
                    },
                    onNewCategoryTap: {
                        showCategoryCreationSheet = true
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
