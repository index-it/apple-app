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
    
    private func syncLists() async {
        do {
            let (lists, categories, _) = try await ixApiClient.syncLists(excludeItems: true)
            
            try context.transaction {
                try context.delete(model: IxList.self)
                for ixList in lists {
                    context.insert(ixList)
                }
                
                try context.delete(model: IxListCategory.self)
                for ixCategory in categories {
                    context.insert(ixCategory)
                }
            }
            
            try? await IxSystemIntegration.handleNewEntities(lists.map(IxListEntity.init))
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
                if await SyncRegister.shared.hasExpired(SyncResource.listsExcludedItemsSync, threshold: 86_400_000) {
                    await syncLists()
                }
            }
        }
    }
}

#Preview {
    ListSelectorMenu { _, _ in }
}
