//
//  ListsHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import SwiftData
import MCEmojiPicker
import IxCoreKit

struct ListsTabView: View {
    @Environment(\.modelContext) private var context
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var errorService: ErrorStateService
    
    @AppStorage(AppStorageKeys.loggedInUser) var user: User?
    
    @Query private var lists: [IxList]
    
    @State private var showPaywall: Bool = false
    
    // MARK: List creation
    @State private var showCreationSheet = false
    @State private var newListColor: Color = ColorHelper.randomIxColor()
    @State private var newListEmoji: String = EmojiHelper.randomEmoji()
    
    // MARK: Selected list
    @State private var selectedList: IxList? = nil
    @State private var showEditSheet = false
    @State private var showDeleteConfirmationDialog = false
    
    // MARK: Sorting and filtering
    @AppStorage(AppStorageKeys.Lists.sorting) private var sorting = AppStorageKeys.Defaults.listsSorting
    @AppStorage(AppStorageKeys.Lists.sortOrder) private var sortingOrder = AppStorageKeys.Defaults.listsSortOrder
    @AppStorage(AppStorageKeys.Lists.filter) private var filter = AppStorageKeys.Defaults.listsFilter
    
    // MARK: Share sheet
    @State private var selectedListUsersWithAccess: [IxListSingleUserAccessInfo] = []
    @State private var showShareSheet = false
    @State private var showUserInvitationSuccessAlert = false
    @State private var loadingSelectedListPublic: Bool = false
    @State private var loadingSelectedListUsers: Bool = false
    @State private var loadingSelectedListUserInvite: Bool = false
    @State private var loadingSelectedListUserEditOrRevokePermissions: String? = nil
    @State private var showLeaveListConfirmation = false
    
    
    private func saveList(_ list: IxList) async throws {
        try context.transaction {
            context.insert(list)
        }
    }
    
    // MARK: - List CRUD
    private func fetchLists() async {
        do {
            let lists = try await ixApiClient.getLists()
            
            try context.transaction {
                try context.delete(model: IxList.self)
                
                lists.forEach { ixList in
                    context.insert(ixList)
                }
            }
        } catch {
            errorService.insert(.localizedError(title: "Error loading lists", error: error))
        }
    }
    
    private func createList(name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.createList(name: name, icon: emoji, color: color.hexString, archived: false, is_public: isPublic)
            
            try await saveList(list)
        } catch IxApiClientError.proRequired(_) {
            showPaywall = true
        } catch {
            errorService.insert(.localizedError(title: "Error creating list", error: error))
        }
    }
    
    private func editList(id: String, name: String, color: String, emoji: String, archived: Bool, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.editList(id: id, name: name, icon: emoji, color: color, archived: archived, is_public: isPublic)
            
            try await saveList(list)
        } catch {
            errorService.insert(.localizedError(title: "Error editing list", error: error))
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
            errorService.insert(.localizedError(title: "Error deleting list", error: error))
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
            errorService.insert(.localizedError(title: "Error leaving list", error: error))
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
                
                errorService.insert(.localizedError(title: "Error updating list", error: error))
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
            errorService.insert(.localizedError(title: "Error fetching users", error: error))
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
                errorService.insert(.localizedError(title: "Error inviting user", error: error))
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
                errorService.insert(.localizedError(title: "Error changing user permissions", error: error))
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
                errorService.insert(.localizedError(title: "Error revoking user access", error: error))
            }
        }
    }
    
    
    var body: some View {
        NavigationView {
            ListsDisplayerView
                .navigationTitle("Your lists")
                .floatingActionButton("plus") {
                    if let user = user, !user.has_pro && lists.count >= 7 {
                        showPaywall = true
                    } else {
                        showCreationSheet = true
                    }
                }
//                .toolbar {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Menu {
//                            Picker(selection: $filter) {
//                                ForEach(ListsFilter.allCases) { filter in
//                                    Text(filter.label)
//                                        .tag(filter)
//                                }
//                            } label: {
//                                Label("Filter", systemImage: "line.3.horizontal.decrease")
//                            }.pickerStyle(.menu)
//                            
//                            Section {
//                                Picker(selection: $sorting) {
//                                    ForEach(ListsSorting.allCases) { filter in
//                                        Text(filter.label)
//                                            .tag(filter)
//                                    }
//                                } label: {
//                                    Label("Sorting", systemImage: "arrow.up.arrow.down")
//                                }.pickerStyle(.menu)
//                            }
//                        } label: {
//                            Label("Options", systemImage: "ellipsis.circle")
//                                .labelStyle(.iconOnly)
//                        }
//                    }
//                }
                .paywallCover(isPresented: $showPaywall)
                .sheet(isPresented: $showShareSheet) {
                    ListSharingSheet(
                        showSheet: $showShareSheet,
                        showUserInvitationSuccessAlert: $showUserInvitationSuccessAlert,
                        loadingPublic: $loadingSelectedListPublic,
                        loadingUsers: $loadingSelectedListUsers,
                        loadingUserInvite: $loadingSelectedListUserInvite,
                        loadingUserEditOrDelete: $loadingSelectedListUserEditOrRevokePermissions,
                        isPublic: $selectedList.wrappedValue?.isPublic ?? false,
                        usersWithAccess: $selectedListUsersWithAccess
                    ) { isPublic in
                        Task {
                            await editListPublic(isPublic: isPublic)
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
                .sheet(isPresented: $showCreationSheet) {
                    ListFormSheet(
                        showSheet: $showCreationSheet,
                        name: "",
                        color: newListColor,
                        emoji: newListEmoji,
                        isPublic: false,
                        namePlaceholder: "List name",
                        colors: ColorHelper.ixColors
                    ) { name, color, emoji, isPublic in
                        Task {
                            await createList(name: name, color: color, emoji: emoji, isPublic: isPublic)
                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $showEditSheet) {
                    ListFormSheet(
                        showSheet: $showEditSheet,
                        name: selectedList?.name ?? "",
                        color: selectedList?.color.toColor() ?? Color.accentColor,
                        emoji: selectedList?.icon ?? EmojiHelper.randomEmoji(),
                        isPublic: selectedList?.isPublic ?? false,
                        namePlaceholder: "List name",
                        colors: ColorHelper.ixColors
                    ) { name, color, emoji, isPublic in
                        if let selectedList {
                            Task {
                                await editList(id: selectedList.id, name: name, color: color.hexString, emoji: emoji, archived: selectedList.archived, isPublic: isPublic)
                            }
                        }
                    }.presentationDetents([.large])
                }
                .confirmationDialog(
                    Text("Confirm deletion"),
                    isPresented: $showDeleteConfirmationDialog,
                    titleVisibility: .visible,
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
                .confirmationDialog(
                    Text("Leave list"),
                    isPresented: $showLeaveListConfirmation,
                    titleVisibility: .visible,
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
        }
        .onAppear {
            Task {
                let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.lists)
                
                if (shouldSync) {
                    await fetchLists()
                }
            }
        }
        .onChange(of: showCreationSheet) {
            if showCreationSheet {
                newListEmoji = EmojiHelper.randomEmoji()
                newListColor = ColorHelper.randomIxColor()
            }
        }
    }
    
    
    private var ListsDisplayerView: some View {
        ListsDisplayer(
            userId: user?.id ?? "",
            filter: filter,
            sorting: sorting,
            sortOrder: sortingOrder,
            onFilterClear: {
                filter = .all
            },
            onCreation: {
                showCreationSheet = true
            },
            onListCardTap: { list in
                navigationManager.push(.listRoute(listId: list.id))
            },
            onShare: { list in
                selectedList = list
                if list.userId == user?.id {
                    Task {
                        await fetchListUsersWthAccess(listId: list.id)
                    }
                    showShareSheet = true
                } else {
                    showLeaveListConfirmation = true
                }
                
            },
            onArchive: { list in
                Task {
                    await editList(id: list.id, name: list.name, color: list.color, emoji: list.icon, archived: true, isPublic: list.isPublic)
                }
            },
            onEdit: { list in
                selectedList = list
                showEditSheet = true
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

