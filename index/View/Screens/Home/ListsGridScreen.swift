//
//  ListsGridScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import _AppIntents_SwiftUI
import IxCoreKit
import MCEmojiPicker
import SwiftData
import SwiftUI

struct ListsGridScreen: View {
    @Environment(IxNavigator.self) private var navigator
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.modelContext) private var context
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @Environment(\.showError) private var showError

    @AppStorage(AppStorageKeys.loggedInUser) var user: User?

    @Query private var lists: [IxList]
    private var archived: Bool

    // MARK: List creation

    @State private var isAddingList = false
    @State private var newListColor: Color = ColorHelper.randomIxColor()
    @State private var newListEmoji: String = EmojiHelper.randomEmojiForPickerInitial()

    // MARK: Selected list

    @State private var selectedList: IxList? = nil
    @State private var isEditingList = false
    @State private var showShareSheet = false
    @State private var showLeaveListConfirmation = false
    @State private var showDeleteConfirmationDialog = false

    // MARK: Sorting and filtering

    @AppStorage(AppStorageKeys.Lists.sorting) private var sorting = AppStorageKeys.Defaults.listsSorting
    @AppStorage(AppStorageKeys.Lists.sortOrder) private var sortOrder = AppStorageKeys.Defaults.listsSortOrder
    @AppStorage(AppStorageKeys.Lists.filter) private var filter = AppStorageKeys.Defaults.listsFilter

    // MARK: Quick add sheet

    @State private var showQuickAddSheet: Bool = false
    @State private var quickAddSheetMultiMode: Bool = false

    init(archived: Bool) {
        self.archived = archived

        let listsDescriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.archived == archived
            }
        )

        _lists = Query(listsDescriptor)
    }

    private func saveList(_ list: IxList) async throws {
        try context.transaction {
            context.insert(list)
        }

        try? await IxSystemIntegration.handleNewEntity(IxListEntity(list: list))
    }

    // MARK: - List CRUD

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
        } catch {
            showError(.localizedError(title: "Error loading lists", error: error))
        }
    }

    private func createList(name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.createList(name: name, icon: emoji, color: color.hexString, archived: false, is_public: isPublic)

            try await saveList(list)
        } catch IxApiClientError.proRequired(_) {
            showPaywall()
        } catch {
            showError(.localizedError(title: "Error creating list", error: error))
        }
    }

    private func editList(id: String, name: String, color: String, emoji: String, archived: Bool, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.editList(id: id, name: name, icon: emoji, color: color, archived: archived, is_public: isPublic)

            try await saveList(list)
        } catch {
            showError(.localizedError(title: "Error editing list", error: error))
        }
    }

    private func deleteList(id: String) async {
        do {
            try await ixApiClient.deleteList(id: id)
            try context.transaction {
                try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
            }

            try? await IxSystemIntegration.handleEntityDeletion(id, of: IxListEntity.self)
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
                }
            } catch {}
        } catch {
            showError(.localizedError(title: "Error deleting list", error: error))
        }
    }

    private func leaveList(id: String) async {
        do {
            try await ixApiClient.leaveList(id: id)
            try context.transaction {
                try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
            }

            try? await IxSystemIntegration.handleEntityDeletion(id, of: IxListEntity.self)
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
                }
            } catch {}
        } catch {
            showError(.localizedError(title: "Error leaving list", error: error))
        }
    }

    var body: some View {
        ListsDisplayerView
            .navigationTitle(archived ? "Archived lists" : "Your lists")
            .navigationBarTitleDisplayMode(archived ? .inline : .large)
            .if(!lists.isEmpty) { view in
                view.floatingActionButton(
                    "plus",
                    action: {
                        showQuickAddSheet = true
                    },
                    longPressAction: {
                        quickAddSheetMultiMode = true
                        showQuickAddSheet = true
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigator.push(.settings)
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                if !archived {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let user = user, !user.has_pro && lists.count >= 7 {
                                showPaywall()
                            } else {
                                isAddingList = true
                            }
                        } label: {
                            Image(systemName: "text.pad.header.badge.plus")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Menu {
                            Picker(selection: $sorting) {
                                ForEach(ListsSorting.allCases) { sorting in
                                    Text(sorting.label)
                                        .tag(sorting)
                                }
                            } label: {
                                Text("Sorting")
                            }

                            //                            if sorting != .manual {
                            Picker(selection: $sortOrder) {
                                Text(SortOrder.forward.labelForListsSorting(sorting))
                                    .tag(SortOrder.forward)

                                Text(SortOrder.reverse.labelForListsSorting(sorting))
                                    .tag(SortOrder.reverse)
                            } label: {
                                Text("Sort Order")
                            }
                            //                            }
                        } label: {
                            Button {} label: {
                                Text("Sort by")
                                Text(sorting.label)
                                Image(systemName: "arrow.up.arrow.down")
                            }
                        }

                        Picker(selection: $filter) {
                            ForEach(ListsFilter.allCases) { filter in
                                Text(filter.label)
                                    .tag(filter)
                            }
                        } label: {
                            Button {} label: {
                                Text("Filter")
                                Text(filter.label)
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }.pickerStyle(.menu)

                        Divider()

                        if !archived {
                            Button {
                                navigator.push(.archivedLists)
                            } label: {
                                Label("Archived lists", systemImage: "archivebox")
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) { [selectedList] in
                ListSharingSheet(listId: selectedList?.id ?? "") {
                    showShareSheet = false
                }.presentationDetents([.large])
            }
            .sheet(isPresented: $isAddingList) {
                ListEditor(
                    isPresented: $isAddingList,
                    addingNew: true,
                    name: "",
                    color: newListColor,
                    emoji: newListEmoji,
                    isPublic: false,
                    colors: ColorHelper.ixColors
                ) { name, color, emoji, isPublic in
                    Task {
                        await createList(name: name, color: color, emoji: emoji, isPublic: isPublic)
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $isEditingList) {
                ListEditor(
                    isPresented: $isEditingList,
                    addingNew: false,
                    name: selectedList?.name ?? "",
                    color: selectedList?.color.toColor() ?? Color.accentColor,
                    emoji: selectedList?.icon ?? EmojiHelper.randomEmojiForPickerInitial(),
                    isPublic: selectedList?.isPublic ?? false,
                    colors: ColorHelper.ixColors
                ) { name, color, emoji, isPublic in
                    if let selectedList {
                        Task {
                            await editList(id: selectedList.id, name: name, color: color.hexString, emoji: emoji, archived: selectedList.archived, isPublic: isPublic)
                        }
                    }
                }.presentationDetents([.large])
            }
            .sheet(isPresented: $showQuickAddSheet) {
                QuickAddItemView(
                    multi: quickAddSheetMultiMode,
                    onCancel: {
                        showQuickAddSheet = false
                        quickAddSheetMultiMode = false
                    }
                )
            }
            .alert(
                Text("Confirm deletion"),
                isPresented: $showDeleteConfirmationDialog,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let selectedList {
                            Task {
                                await deleteList(id: selectedList.id)
                            }
                        }
                    }

                    Button("Keep", role: .cancel) {
                        showDeleteConfirmationDialog = false
                    }
                },
                message: {
                    Text("Are you sure you want to delete the list \(selectedList?.name ?? "")? This action is irreversible!")
                }
            )
            .alert(
                Text("Leave list"),
                isPresented: $showLeaveListConfirmation,
                actions: {
                    Button("Leave", role: .destructive) {
                        if let selectedList {
                            Task {
                                await leaveList(id: selectedList.id)
                            }
                        }
                    }

                    Button("Stay", role: .cancel) {
                        showLeaveListConfirmation = false
                    }
                },
                message: {
                    Text("The list \(selectedList?.name ?? "") was shared with you! Do you want to leave the list and lose access to it?")
                }
            )
            .onAppear {
                Task {
                    let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.lists)

                    if shouldSync {
                        await fetchLists()
                    }
                }
            }
            .onChange(of: navigator.itemCreatePresented, initial: true) { _, newValue in
                if newValue {
                    showQuickAddSheet = true
                    navigator.itemCreatePresented = false
                }
            }
            .onChange(of: isAddingList) {
                if isAddingList {
                    newListEmoji = EmojiHelper.randomEmojiForPickerInitial()
                    newListColor = ColorHelper.randomIxColor()
                }
            }
    }

    private var ListsDisplayerView: some View {
        ListsGrid(
            userId: user?.id ?? "",
            filter: filter,
            archived: archived,
            sorting: sorting,
            sortOrder: sortOrder,
            onFilterClear: {
                filter = .all
            },
            onAdd: {
                isAddingList = true
            },
            onListCardTap: { list in
                navigator.push(.listRoute(listId: list.id))

                Task {
                    await IxSystemIntegration.donateIntent(.openList(list))
                }
            },
            onShare: { list in
                selectedList = list
                if list.userId == user?.id {
                    showShareSheet = true
                } else {
                    showLeaveListConfirmation = true
                }

            },
            onEdit: { list in
                selectedList = list
                isEditingList = true
            },
            onArchiveToggle: { list in
                Task {
                    await editList(id: list.id, name: list.name, color: list.color, emoji: list.icon, archived: !list.archived, isPublic: list.isPublic)
                }
            },
            onDelete: { list in
                selectedList = list
                showDeleteConfirmationDialog = true
            },
            onLeave: { list in
                selectedList = list
                showLeaveListConfirmation = true
            }
        )
    }
}
