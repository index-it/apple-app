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
    
    private var listId: String
    
    @Query private var lists: [IxList]
    @State private var list: IxList = IxList.loading()
    
    @Query private var categories: [IxListCategory]
    @State private var selectedCategoryId: String? = nil
    
    
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
    
    var body: some View {
        ScreenContent
            .navigationTitle(list.name)
            .onAppear {
                if SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.list(listId)) {
                    Task {
                        await fetchList()
                    }
                    Task {
                        await fetchCategories()
                        selectedCategoryId = categories.first?.id
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
            Spacer()
            
            CategorySelector(categories: categories, selectedCategoryId: $selectedCategoryId)
        }
    }
}

#Preview {
    ListScreen(listId: "123")
        .environmentObject(IxApiClient())
        .environmentObject(NavigationManager())
}
