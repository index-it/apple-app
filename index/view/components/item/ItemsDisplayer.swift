//
//  ItemsDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import SwiftUI
import SwiftData

struct ItemsDisplayer: View {
    private var listId: String
    private var category: IxListCategory?
    private var withCompleted: Bool
    
    @Query private var items: [IxListItem]
    
    private var color: Color? {
        guard let category = category else {
            return nil
        }
        
        return Color(hexString: category.color)
    }
    
    init(listId: String, category: IxListCategory? = nil, withCompleted: Bool) {
        self.listId = listId
        self.category = category
        self.withCompleted = withCompleted
        
        let categoryId = category?.id
        
        if withCompleted {
            _items = Query(filter: #Predicate { item in
                item.list_id == listId && item.category_id == categoryId
            })
        } else {
            _items = Query(filter: #Predicate { item in
                item.list_id == listId && item.category_id == categoryId && item.completed == false
            })
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(items) { item in
                    Menu {
                        ControlGroup {
                            Button("Open", systemImage: "text.page") {
                                
                            }
                            
                            if item.link != nil {
                                Button("Open link", systemImage: "link") {
                                    
                                }
                            }
                            
                            Button("complete", systemImage: "checkmark") {
                                
                            }
                        }
                        
                        
                        Button("Create task", systemImage: "rectangle.grid.1x2.fill") {
                            
                        }
                        
                        Button("Edit", systemImage: "pencil") {
                            
                        }
                        
                        Section {
                            Menu {
                                Button("Delete", systemImage: "trash") {
                                    
                                }
                                
                                Button("Cancel", role: .cancel) {}
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        ItemCard(item: item, color: color)
                    }
                }
            }
        }
    }
}

struct ItemsDisplayerTest: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach([IxListItem.loading(), IxListItem.loading(), IxListItem.loading(), IxListItem.loading(), IxListItem.loading()]) { item in
                    Menu {
                        ControlGroup {
                            Button("Open", systemImage: "text.page") {
                                
                            }
                            
                            if item.link != nil {
                                Button("Open link", systemImage: "link") {
                                    
                                }
                            }
                            
                            Button("Complete", systemImage: "checkmark") {
                                
                            }
                        }
                        
                        
                        Button("Create task", systemImage: "rectangle.grid.1x2.fill") {
                            
                        }
                        
                        Button("Edit", systemImage: "pencil") {
                            
                        }
                        
                        Section {
                            Menu {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    
                                }
                                
                                Button("Cancel", role: .cancel) {}
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        ItemCard(item: item)
                    }
                }
            }
        }
    }
}

#Preview {
//    ItemsDisplayer(
//        listId: "1",
//        categoryId: nil,
//        withCompleted: false
//    )
    
    ItemsDisplayerTest()
}
