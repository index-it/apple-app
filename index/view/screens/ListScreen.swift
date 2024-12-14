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
    
    @State private var showItemCreationSheet = false
    @FocusState private var newItemNameFocused
    @State private var newItemName = ""
    @State private var newItemLink = ""
    @State private var newItemCategory: String? = nil
    private var isNewItemNameInvalid: Bool {
        newItemName.isEmpty || newItemName.count >= 100
    }
    
    @State private var showCategoryCreationSheet = false
    
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
    
    func setItemCompletion(listId: String, itemId: String, completed: Bool) async {
        do {
            let item = try await ixApiClient.setListItemCompletion(listId: listId, itemId: itemId, completed: completed)
            
            try await saveItem(item)
        } catch {
            
        }
    }
    
    var body: some View {
        ScreenContent
            .sheet(isPresented: $showItemCreationSheet, content: {
                ItemCreationSheet
            })
            .sheet(isPresented: $showCategoryCreationSheet, content: {
                
            })
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
                withCompleted: false,
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
                    // TODO
                },
                onDelete: { item in
                    // TODO
                }
            )
                .padding(.horizontal)
            
            VStack {
                CategorySelector(categories: categories, selectedCategoryId: $selectedCategoryId)
                    .frame(height: CategoryUIDefaults.height + 48)
                    
                
                Text(onCreateNewCategory ? "Create category" : (selectedCategory?.name ?? "Create item"))
            }
        }
    }
    
    private var ItemCreationSheet: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Item name", text: $newItemName)
                    
                    TextField("Link", text: $newItemLink)
                }
            }.frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle("New item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showItemCreationSheet = false
                        } label: {
                            Text("Cancel")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showItemCreationSheet = false
                        } label: {
                            Text("Save")
                        }.disabled(isNewItemNameInvalid)
                    }
                }
                .onAppear {
                    newItemNameFocused = true
                }
        }
    }
}

#Preview {
    ListScreen(listId: "123")
        .environmentObject(IxApiClient())
        .environmentObject(NavigationManager())
}
