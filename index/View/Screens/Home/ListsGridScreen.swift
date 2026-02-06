//
//  ListsGridScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import IxCoreKit
import MCEmojiPicker
import SwiftData
import SwiftUI

struct ListsGridScreen: View {
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.modelContext) private var context
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
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
    @State private var showDeleteConfirmationDialog = false

    // MARK: Sorting and filtering

    @AppStorage(AppStorageKeys.Lists.sorting) private var sorting = AppStorageKeys.Defaults.listsSorting
    @AppStorage(AppStorageKeys.Lists.sortOrder) private var sortOrder = AppStorageKeys.Defaults.listsSortOrder
    @AppStorage(AppStorageKeys.Lists.filter) private var filter = AppStorageKeys.Defaults.listsFilter

    // MARK: Share sheet

    @State private var selectedListUsersWithAccess: [IxListSingleUserAccessInfo] = []
    @State private var selectedListActiveInvites: [IxListInvite] = []
    @State private var showShareSheet = false
    @State private var showUserInvitationSuccessAlert = false
    @State private var loadingSelectedListPublic: Bool = false
    @State private var loadingSelectedListUsers: Bool = false
    @State private var loadingSelectedListUserInvite: Bool = false
    @State private var loadingSelectedListUserEditOrRevokePermissions: String? = nil
    @State private var showLeaveListConfirmation = false
    @State private var inviteEditorConfig = EditorConfig<IxListInvite>()
    @State private var inviteUrl: URL? = nil

    // MARK: Quick add sheet

    @State private var showQuickAddSheet: Bool = false

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
        let listId = list.id
        try context.transaction {
            try context.delete(model: IxList.self, where: #Predicate { $0.id == listId })
            context.insert(list)
        }
        
        IxSystemIntegration.handleNewEntity(IxListEntity(list: list))
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

    // MARK: - LIST SHARING FUNCTIONS

    private func leaveList(id: String) async {
        do {
            try await ixApiClient.leaveList(id: id)
            try context.transaction {
                try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
            }
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

    private func editListPublic(isPublic: Bool) async {
        if let selectedList {
            do {
                loadingSelectedListPublic = true
                let list = try await ixApiClient.editList(id: selectedList.id, name: selectedList.name, icon: selectedList.icon, color: selectedList.color, archived: selectedList.archived, is_public: isPublic)

                loadingSelectedListPublic = false

                try await saveList(list)
            } catch {
                loadingSelectedListPublic = false

                showError(.localizedError(title: "Error updating list", error: error))
            }
        }
    }

    private func fetchListUsersWthAccess(listId: String) async {
        do {
            loadingSelectedListUsers = true
            selectedListUsersWithAccess = try await ixApiClient.getListUsersWithAccess(id: listId)
            loadingSelectedListUsers = false
        } catch {
            loadingSelectedListUsers = false
            showError(.localizedError(title: "Error fetching users", error: error))
        }
    }

    private func fetchListActiveInvites(listId: String) async {
        do {
            selectedListActiveInvites = try await ixApiClient.getListInvites(listId: listId)
        } catch {
            showError(.localizedError(title: "Error fetching active invites", error: error))
        }
    }

    private func inviteUser(email: String, editor: Bool) async {
        if let selectedList {
            do {
                loadingSelectedListUserInvite = true
                let list = try await ixApiClient.inviteUserToList(listId: selectedList.id, email: email, editor: editor)

                if list == nil {
                    showUserInvitationSuccessAlert = true
                }

                loadingSelectedListUserInvite = false
            } catch {
                loadingSelectedListUserInvite = false
                showError(.localizedError(title: "Error inviting user", error: error))
            }
        }
    }

    private func editUserPermissions(email: String, editor: Bool) async {
        if let selectedList {
            do {
                loadingSelectedListUserEditOrRevokePermissions = selectedListUsersWithAccess.first(where: { user in
                    user.email == email
                })?.userId

                let list = try await ixApiClient.inviteUserToList(listId: selectedList.id, email: email, editor: editor)

                loadingSelectedListUserEditOrRevokePermissions = nil

                if let list {
                    try await saveList(list)
                }

                await fetchListUsersWthAccess(listId: selectedList.id)
            } catch {
                loadingSelectedListUserEditOrRevokePermissions = nil
                showError(.localizedError(title: "Error changing user permissions", error: error))
            }
        }
    }

    private func revokeUserAccessFromList(userId: String) async {
        if let selectedList {
            do {
                loadingSelectedListUserEditOrRevokePermissions = userId

                let list = try await ixApiClient.revokeListAccessFromUser(listId: selectedList.id, userId: userId)
                loadingSelectedListUserEditOrRevokePermissions = nil

                try await saveList(list)

                await fetchListUsersWthAccess(listId: selectedList.id)
            } catch {
                loadingSelectedListUserEditOrRevokePermissions = nil
                showError(.localizedError(title: "Error revoking user access", error: error))
            }
        }
    }

    private func createInvite() async {
        if let selectedList {
            do {
                inviteEditorConfig.loading = true
                defer { inviteEditorConfig.loading = false }
                let createData = try inviteEditorConfig.sanitizeAndValidate()

                let invite = try await ixApiClient.createListInvite(
                    listId: selectedList.id,
                    editor: createData.editor,
                    maxUsages: createData.maxUsages,
                    expiresAt: createData.expiresAt,
                    description: createData.description
                )

                inviteEditorConfig.isPresented = false
                if let token = invite.token, let url = URL(string: IxUniversalLinks.listInvite(token)) {
                    inviteUrl = url
                } else {
                    showError(.customMessage(title: "Error creating invite", message: "This should not happend, the developer is investingating this!"))
                }
            } catch {
                showError(.localizedError(title: "Error creating invite", error: error))
            }
        }
    }

    private func deleteInvite(_ inviteId: String) async {
        if let selectedList {
            do {
                try await ixApiClient.deleteListInvite(listId: selectedList.id, inviteId: inviteId)
                await fetchListActiveInvites(listId: selectedList.id)
            } catch {
                showError(.localizedError(title: "Error deleting invite", error: error))
            }
        }
    }

    var body: some View {
        ListsDisplayerView
            .navigationTitle(archived ? "Archived lists" : "Your lists")
            .navigationBarTitleDisplayMode(archived ? .inline : .large)
            .if(!lists.isEmpty, transform: { view in
                view.floatingActionButton(
                    "plus",
                    action: {
                        navigationManager.showQuickAddItemView()
                    },
                    longPressAction: {
                        navigationManager.showQuickAddItemView(multi: true)
                    }
                )
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigationManager.push(.settings)
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
                            Image(systemName: "plus.circle")
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
                                navigationManager.push(.archivedLists)
                            } label: {
                                Label("Archived lists", systemImage: "archivebox")
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) { [selectedList] in
                ListSharingSheet(
                    showSheet: $showShareSheet,
                    showUserInvitationSuccessAlert: $showUserInvitationSuccessAlert,
                    loadingPublic: $loadingSelectedListPublic,
                    loadingUsers: $loadingSelectedListUsers,
                    loadingUserInvite: $loadingSelectedListUserInvite,
                    loadingUserEditOrDelete: $loadingSelectedListUserEditOrRevokePermissions,
                    inviteEditorConfig: $inviteEditorConfig,
                    inviteUrl: $inviteUrl,
                    listId: selectedList?.id ?? "",
                    isPublic: selectedList?.isPublic ?? false,
                    usersWithAccess: $selectedListUsersWithAccess,
                    activeInvites: $selectedListActiveInvites
                ) { isPublic in
                    Task {
                        await editListPublic(isPublic: isPublic)
                    }
                } onCreateInvite: {
                    Task {
                        await createInvite()
                    }
                } onDeleteInvite: { inviteId in
                    Task {
                        await deleteInvite(inviteId)
                    }
                } onUserInvite: { email, editor in
                    Task {
                        await inviteUser(email: email, editor: editor)
                    }
                } onUserEditEditorPermission: { email, editor in
                    Task {
                        await editUserPermissions(email: email, editor: editor)
                    }
                } onUserRevokeAccess: { userId in
                    Task {
                        await revokeUserAccessFromList(userId: userId)
                    }
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
            .sheet(isPresented: $navigationManager.quickAddItemViewPresented) {
                QuickAddItemView(
                    multi: navigationManager.quickAddItemViewMulti,
                    onCancel: {
                        navigationManager.quickAddItemViewPresented = false
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
                navigationManager.push(.listRoute(listId: list.id, categoryId: nil))
            },
            onShare: { list in
                selectedList = list
                if list.userId == user?.id {
                    Task {
                        await fetchListUsersWthAccess(listId: list.id)
                    }
                    Task {
                        await fetchListActiveInvites(listId: list.id)
                    }
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
