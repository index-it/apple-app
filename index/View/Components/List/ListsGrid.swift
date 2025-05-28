//
//  ListsDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import SwiftUI
import SwiftData
import IxCoreKit

struct ListsGrid: View {
    @Query private var lists: [IxList]
    
    private var userId: String
    private var filter: ListsFilter
    private var onFilterClear: () -> ()
    private var onAdd: () -> ()
    private var onListCardTap: (_ list: IxList) -> ()
    private var onShare: (_ list: IxList) -> ()
    private var onArchive: (_ list: IxList) -> ()
    private var onEdit: (_ list: IxList) -> ()
    private var onDelete: (_ list: IxList) -> ()
    private var onLeave: (_ list: IxList) -> ()
    
    init(
        userId: String,
        filter: ListsFilter,
        sorting: ListsSorting,
        sortOrder: SortOrder,
        onFilterClear: @escaping () -> (),
        onAdd: @escaping () -> Void,
        onListCardTap: @escaping (_: IxList) -> Void,
        onShare: @escaping (_: IxList) -> Void,
        onArchive: @escaping (_: IxList) -> Void,
        onEdit: @escaping (_: IxList) -> Void,
        onDelete: @escaping (_: IxList) -> Void,
        onLeave: @escaping (_: IxList) -> Void
    ) {
        self.userId = userId
        self.filter = filter
        self.onFilterClear = onFilterClear
        self.onAdd = onAdd
        self.onListCardTap = onListCardTap
        self.onShare = onShare
        self.onArchive = onArchive
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onLeave = onLeave
        
        var filterPredicate = #Predicate<IxList> { _ in
            true
        }
        
        if filter == .ownedByMe {
            filterPredicate = #Predicate<IxList> { list in
                list.userId == userId
            }
        } else if filter == .sharedWithMe {
            filterPredicate = #Predicate<IxList> { list in
                list.userId != userId
            }
        }
        
        let sortDescriptor = switch sorting {
        case .name:
            SortDescriptor(\IxList.name, order: sortOrder)
        case .creationDate:
            SortDescriptor(\IxList.createdAt, order: sortOrder)
        case .manual:
            SortDescriptor(\IxList.createdAt, order: sortOrder)
        }
        
        _lists = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    
    var body: some View {
        ListsGridView
            .overlay {
                if lists.isEmpty {
                    ContentUnavailableView {
                        Label(filter == .sharedWithMe ? "No shared lists" : "No lists", systemImage: "binoculars")
                    } description: {
                        Text(filter == .sharedWithMe ? "You are not part of any shared list yet!" : "You don't have any list yet!")
                    } actions: {
                        if filter == .sharedWithMe {
                            Button {
                                onFilterClear()
                            } label: {
                                Label("Clear filters", systemImage: "xmark")
                            }.buttonStyle(.borderedProminent)
                        } else {
                            Button {
                                onAdd()
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
                        owner: list.userId == userId,
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
