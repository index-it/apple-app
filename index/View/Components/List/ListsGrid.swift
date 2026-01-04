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
    private var archived: Bool
    private var onFilterClear: () -> ()
    private var onAdd: () -> ()
    private var onListCardTap: (_ list: IxList) -> ()
    private var onShare: (_ list: IxList) -> ()
    private var onEdit: (_ list: IxList) -> ()
    private var onArchiveToggle: (_ list: IxList) -> ()
    private var onDelete: (_ list: IxList) -> ()
    private var onLeave: (_ list: IxList) -> ()
    
    init(
        userId: String,
        filter: ListsFilter,
        archived: Bool,
        sorting: ListsSorting,
        sortOrder: SortOrder,
        onFilterClear: @escaping () -> (),
        onAdd: @escaping () -> Void,
        onListCardTap: @escaping (_: IxList) -> Void,
        onShare: @escaping (_: IxList) -> Void,
        onEdit: @escaping (_: IxList) -> Void,
        onArchiveToggle: @escaping (_: IxList) -> Void,
        onDelete: @escaping (_: IxList) -> Void,
        onLeave: @escaping (_: IxList) -> Void
    ) {
        self.userId = userId
        self.filter = filter
        self.archived = archived
        self.onFilterClear = onFilterClear
        self.onAdd = onAdd
        self.onListCardTap = onListCardTap
        self.onShare = onShare
        self.onArchiveToggle = onArchiveToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onLeave = onLeave
        
        var filterPredicate = #Predicate<IxList> { list in
            list.archived == archived
        }
        
        if filter == .ownedByMe {
            filterPredicate = #Predicate<IxList> { list in
                list.userId == userId && list.archived == archived
            }
        } else if filter == .sharedWithMe {
            filterPredicate = #Predicate<IxList> { list in
                list.userId != userId && list.archived == archived
            }
        }
        
        let sortDescriptor = switch sorting {
        case .name:
            SortDescriptor(\IxList.name, order: sortOrder)
        case .creationDate:
            SortDescriptor(\IxList.createdAt, order: sortOrder)
//        case .manual:
//            SortDescriptor(\IxList.createdAt, order: sortOrder)
        }
        
        _lists = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    
    var body: some View {
        ListsGridView
            .overlay {
                if lists.isEmpty {
                    ContentUnavailableView {
                        Label(filter == .sharedWithMe ? "No shared lists" : (archived ? "Archive is empty" : "No lists"), systemImage: archived ? "archivebox" : "binoculars")
                    } description: {
                        Text(filter == .sharedWithMe ? "You are not part of any shared list yet!" : (archived ? "You didn't archive any list" : "You don't have any list yet!"))
                    } actions: {
                        if filter == .sharedWithMe {
                            Button {
                                onFilterClear()
                            } label: {
                                Label("Clear filters", systemImage: "xmark")
                            }.buttonStyle(.glassProminent)
                        } else if !archived {
                            Button {
                                onAdd()
                            } label: {
                                Label("Create a list", systemImage: "plus")
                            }.buttonStyle(.glassProminent)
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
                        onArchiveToggle: {
                            onArchiveToggle(list)
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
