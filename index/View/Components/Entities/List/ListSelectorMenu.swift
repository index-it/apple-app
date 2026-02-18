//
//  ListSelectorMenu.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/02/26.
//

import IxCoreKit
import SwiftUI
import SwiftData

struct ListSelectorMenu: View {
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @Environment(\.modelContext) private var context
    
    var onSelect: (IxList, IxListCategory?) -> Void
    
    @Query(sort: [SortDescriptor(\IxList.name)]) private var lists: [IxList]
    @Query(sort: [SortDescriptor(\IxListCategory.name)]) private var categories: [IxListCategory]
    
    @State private var category: IxListCategory? = nil
    
    private func fetchLists() async {
        do {
            let lists = try await ixApiClient.getLists()
            
            try context.transaction {
                try context.delete(model: IxList.self)
                
                for ixList in lists {
                    context.insert(ixList)
                }
            }
            
            try? await IxSystemIntegration.handleNewEntities(lists.map(IxListEntity.init))
        } catch {}
    }
    
    private func fetchCategories(listId: String) async {
        do {
            let categories = try await ixApiClient.getListCategories(listId: listId)
            
            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in
                        category.listId == listId
                    }
                )
                
                for category in categories {
                    context.insert(category)
                }
            }
            
            try? await IxSystemIntegration.handleNewEntities(categories.map(IxListCategoryEntity.init))
        } catch {}
    }
    
    var body: some View {
        Menu {
            ForEach(lists, id: \.id) { list in
                Menu {
                    Button {
                        onSelect(list, nil)
                    } label: {
                        Text("Uncategorized")
                    }
                    
                    ForEach(categories.filter { $0.listId == list.id }, id: \.id) { category in
                        Button {
                            onSelect(list, category)
                        } label: {
                            Text(category.name)
                        }
                    }
                } label: {
                    Text("\(list.icon) \(list.name)")
                }
            }
        } label: {
            Label("Move", systemImage: "tray.and.arrow.up")
        }
        .onAppear {
            Task {
                if await SyncRegister.shared.hasExpired(SyncResource.lists, threshold: 86_400_000) {
                    await fetchLists()
                }
            }
        }
        .onChange(of: lists) { _, newValue in
            for list in newValue {
                Task {
                    if await SyncRegister.shared.hasExpired(SyncResource.listCategories(list.id), threshold: 86_400_000) {
                        await fetchCategories(listId: list.id)
                    }
                }
            }
        }
    }
}

#Preview {
    ListSelectorMenu { _, _ in }
}
