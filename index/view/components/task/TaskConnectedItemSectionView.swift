//
//  TaskConnectedItemSectionView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/03/25.
//
import SwiftUI
import SwiftData

struct TaskConnectedItemSectionView: View {
    private var item: IxListItem?
    
    @Query private var categories: [IxListCategory]
    @Query private var lists: [IxList]
    
    private var onDelete: () -> Void
    
    init(
        item: IxListItem?,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.onDelete = onDelete
        
        let categoryId = item?.category_id
        let listId = item?.list_id
        
        if let listId = listId {
            var listDescriptor: FetchDescriptor<IxList>
            
            listDescriptor = FetchDescriptor<IxList> (
                predicate: #Predicate { list in
                    list.id == listId
                }
            )
            
            listDescriptor.fetchLimit = 1
            _lists = Query(listDescriptor)
            
            if let categoryId = categoryId {
                var categoryDescriptor: FetchDescriptor<IxListCategory>
                
                categoryDescriptor = FetchDescriptor<IxListCategory> (
                    predicate: #Predicate { category in
                        category.id == categoryId
                    }
                )
                
                categoryDescriptor.fetchLimit = 1
                _categories = Query(categoryDescriptor)
            } else {
                let categoryDescriptor = FetchDescriptor<IxListCategory> (
                    predicate: #Predicate { _ in false }
                )
                
                _categories = Query(categoryDescriptor)
            }
        } else {
            let categoryDescriptor = FetchDescriptor<IxListCategory> (
                predicate: #Predicate { _ in false }
            )
            
            _categories = Query(categoryDescriptor)
            
            let listDescriptor = FetchDescriptor<IxList> (
                predicate: #Predicate { _ in false }
            )
            
            _lists = Query(listDescriptor)
        }
    }
    
    var body: some View {
        HStack {
            Label(title: {
                Text("Connected to " + [lists.first?.name, categories.first?.name].compactMap { $0 }.joined(separator: " / "))
            }, icon: {
                Image(systemName: "app.connected.to.app.below.fill")
            })
            .labelStyle(ColorfulIconLabelStyle(color: .blue))
            
            Spacer()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle")
            }
        }
    }
}
