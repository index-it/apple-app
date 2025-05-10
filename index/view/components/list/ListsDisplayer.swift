//
//  ListsDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import SwiftUI
import SwiftData
import IxCoreKit

struct ListsDisplayer: View {
    @Query private var lists: [IxList]
    
    private var userId: String
    private var filter: ListFilter
    private var onFilterClear: () -> ()
    private var onCreation: () -> ()
    private var onListCardTap: (_ list: IxList) -> ()
    private var onShare: (_ list: IxList) -> ()
    private var onEdit: (_ list: IxList) -> ()
    private var onDelete: (_ list: IxList) -> ()
    private var onLeave: (_ list: IxList) -> ()
    
    init(
        userId: String,
        filter: ListFilter,
        sorting: ListSorting,
        sortOrder: SortOrder,
        onFilterClear: @escaping () -> (),
        onCreation: @escaping () -> Void,
        onListCardTap: @escaping (_: IxList) -> Void,
        onShare: @escaping (_: IxList) -> Void,
        onEdit: @escaping (_: IxList) -> Void,
        onDelete: @escaping (_: IxList) -> Void,
        onLeave: @escaping (_: IxList) -> Void
    ) {
        self.userId = userId
        self.filter = filter
        self.onFilterClear = onFilterClear
        self.onCreation = onCreation
        self.onListCardTap = onListCardTap
        self.onShare = onShare
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onLeave = onLeave
        
        var filterPredicate = #Predicate<IxList> { _ in
            true
        }
        
        if filter == .owner {
            filterPredicate = #Predicate<IxList> { list in
                list.userId == userId
            }
        } else if filter == .shared {
            filterPredicate = #Predicate<IxList> { list in
                list.userId != userId
            }
        }
        
        let sortOrder = if sortingOrder == .newestFirst {
            SortOrder.reverse
        } else {
            SortOrder.forward
        }
        
        let sortDescriptor = switch sorting {
        case .name:
            SortDescriptor(\IxList.name, order: sortOrder)
        case .creation:
            SortDescriptor(\IxList.created_at, order: sortOrder)
        }
        
        _lists = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    
    var body: some View {
        ListsGridView
            .overlay {
                if lists.isEmpty {
                    ContentUnavailableView {
                        Label(filter == .shared ? "No shared lists" : "No lists", systemImage: "binoculars")
                    } description: {
                        Text(filter == .shared ? "You are not part of any shared list yet!" : "You don't have any list yet!")
                    } actions: {
                        if filter == .shared {
                            Button {
                                onFilterClear()
                            } label: {
                                Label("Clear filters", systemImage: "xmark")
                            }.buttonStyle(.borderedProminent)
                        } else {
                            Button {
                                onCreation()
                            } label: {
                                Label("Create a list", systemImage: "plus")
                            }.buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
    }
    
    private var ListsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(lists) { list in
                    ListCard(
                        list: list,
                        owner: list.user_id == userId,
                        onTap: {
                            onListCardTap(list)
                        },
                        onShare: {
                            onShare(list)
                        },
                        onEdit: {
                            onEdit(list)
                        },
                        onDelete: {
                           onDelete(list)
                        },
                        onLeave: {
                            onLeave(list)
                        }
                    )
                }
            }.padding()
        }
    }
}

#Preview {
//    ListsDisplayer()
}
