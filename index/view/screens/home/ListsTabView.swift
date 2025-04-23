//
//  ListsHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import SwiftData
import MCEmojiPicker

struct ListsTabView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.modelContext) private var context
    
    @AppStorage(AppStorageKeys.logged_in_user) var user: User?
    @AppStorage(AppStorageKeys.colors_suggestions) var colorsSuggested: [Color] = AppStorageKeys.Defaults.colors
    
    @Query private var lists: [IxList]
    
    @State private var showPaywall: Bool = false
    
    // MARK: List creation
    @State private var showCreationSheet = false
    @State private var newListNamePlaceholder: String? = nil
    @State private var newListColor: Color? = nil
    @State private var newListEmoji: String = String.randomEmoji()
    
    // MARK: Selected list
    @State private var selectedList: IxList? = nil
    @State private var showEditSheet = false
    @State private var showDeleteConfirmationDialog = false
    
    // MARK: Sorting and filtering
    @AppStorage(AppStorageKeys.list_sorting) private var sorting: ListSorting = AppStorageKeys.Defaults.list_sorting
    @AppStorage(AppStorageKeys.list_reverse_sorting) private var reverseSorting = AppStorageKeys.Defaults.list_reverse_sorting
    @AppStorage(AppStorageKeys.list_filter) private var filter: ListFilter = AppStorageKeys.Defaults.list_filter

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
    
    // MARK: - Suggestions
    func fetchListTemplateSuggestion() async {
        do {
            let template = try await ixApiClient.getListTemplateSuggestion()
            
            newListNamePlaceholder = template.name
            newListColor = Color(hexString: template.color)
        } catch {
            
        }
    }
    
    func fetchColorsSuggestion() async {
        do {
            colorsSuggested = try await ixApiClient.getColorsSuggestion().map { Color(hexString: $0) }
        } catch {
            
        }
    }
    
    // MARK: - List CRUD
    func fetchLists() async {
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
    
    func createList(name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.createList(name: name, icon: emoji, color: color.hexString(), is_public: isPublic)
            
            try await saveList(list)
        } catch IxApiClientError.ProRequired(_) {
            showPaywall = true
        } catch {
            errorService.insert(.localizedError(title: "Error creating list", error: error))
        }
    }
    
    func editList(id: String, name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.editList(id: id, name: name, icon: emoji, color: color.hexString(), is_public: isPublic)
            
            try await saveList(list)
        } catch {
            errorService.insert(.localizedError(title: "Error editing list", error: error))
        }
    }
    
    func deleteList(id: String) async {
        do {
            try await ixApiClient.deleteList(id: id)
            try context.transaction {
                try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
            }
        } catch IxApiClientError.NotFound {
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
    func leaveList(id: String) async {
        do {
            try await ixApiClient.leaveList(id: id)
            try context.transaction {
                try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
            }
        } catch IxApiClientError.NotFound {
            do {
                try context.transaction {
                    try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
                }
            } catch {}
        } catch {
            errorService.insert(.localizedError(title: "Error leaving list", error: error))
        }
    }
    
    func editListPublic(isPublic: Bool) async {
        if let selectedList {
            do {
                loadingSelectedListPublic = true
                let list = try await ixApiClient.editList(id: selectedList.id, name: selectedList.name, icon: selectedList.icon, color: selectedList.color, is_public: isPublic)
                
                loadingSelectedListPublic = false
                
                try await saveList(list)
            } catch {
                loadingSelectedListPublic = false
                
                errorService.insert(.localizedError(title: "Error updating list", error: error))
            }
        }
    }
    
    func fetchListUsersWthAccess(listId: String) async {
        do {
            loadingSelectedListUsers = true
            selectedListUsersWithAccess = try await ixApiClient.getListUsersWithAccess(id: listId)
            loadingSelectedListUsers = false
        } catch {
            loadingSelectedListUsers = false
            errorService.insert(.localizedError(title: "Error fetching users", error: error))
        }
    }
    
    func inviteUser(email: String, editor: Bool) async {
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

    func editUserPermissions(email: String, editor: Bool) async {
        if let selectedList {
            do {
                loadingSelectedListUserEditOrRevokePermissions = selectedListUsersWithAccess.first(where: { user in
                    user.email == email
                })?.user_id
                
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
    
    func revokeUserAccessFromList(userId: String) async {
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
            ListsDisplayer(
                userId: user?.id ?? "",
                filter: filter,
                sorting: sorting,
                reverseSorting: reverseSorting,
                onFilterClear: {
                    filter = .all
                },
                onCreation: {
                    showCreationSheet = true
                },
                onListCardTap: { list in
                    navigationManager.push(navigationRoute: .listRoute(listId: list.id))
                },
                onShare: { list in
                    selectedList = list
                    if list.user_id == user?.id {
                        Task {
                            await fetchListUsersWthAccess(listId: list.id)
                        }
                        showShareSheet = true
                    } else {
                        showLeaveListConfirmation = true
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
            ).navigationTitle("Your lists")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let user = user, !user.has_pro && lists.count >= 7 {
                                showPaywall = true
                            } else {
                                showCreationSheet = true
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                       
                        Menu {
                            Picker(selection: $filter) {
                                ForEach(ListFilter.allCases) { filter in
                                    Text(filter.rawValue)
                                        .tag(filter)
                                }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease")
                            }.pickerStyle(.menu)
                            
                            Section {
                                Picker(selection: $sorting) {
                                    ForEach(ListSorting.allCases) { filter in
                                        Text(filter.rawValue)
                                            .tag(filter)
                                    }
                                } label: {
                                    Label("Sorting", systemImage: "arrow.up.arrow.down")
                                }.pickerStyle(.menu)
                                
                                Toggle("Reverse", isOn: $reverseSorting)
                            }
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
                .paywallCover(isPresented: $showPaywall)
                .sheet(isPresented: $navigationManager.showCreateItemSheet) {
                    AddListItemFormSheet {
                        navigationManager.showCreateItemSheet = false
                    }.presentationDetents([.large])
                }
                .sheet(isPresented: $showShareSheet) {
                    ListSharingSheet(
                        showSheet: $showShareSheet,
                        showUserInvitationSuccessAlert: $showUserInvitationSuccessAlert,
                        loadingPublic: $loadingSelectedListPublic,
                        loadingUsers: $loadingSelectedListUsers,
                        loadingUserInvite: $loadingSelectedListUserInvite,
                        loadingUserEditOrDelete: $loadingSelectedListUserEditOrRevokePermissions,
                        isPublic: $selectedList.wrappedValue?.is_public ?? false,
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
                        color: newListColor ?? Color.green,
                        emoji: newListEmoji,
                        isPublic: false,
                        namePlaceholder: newListNamePlaceholder ?? "List name",
                        colors: colorsSuggested
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
                        color: selectedList?.color.toColor(fallback: .green) ?? Color.green,
                        emoji: selectedList?.icon ?? String.randomEmoji(),
                        isPublic: selectedList?.is_public ?? false,
                        namePlaceholder: newListNamePlaceholder ?? "List name",
                        colors: colorsSuggested
                    ) { name, color, emoji, isPublic in
                        if let selectedList {
                            Task {
                                await editList(id: selectedList.id, name: name, color: color, emoji: emoji, isPublic: isPublic)
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
        }.onAppear {
            Task {
                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.LISTS)
                
                if (shouldSync) {
                    await fetchLists()
                }
            }
            
            Task {
                await fetchListTemplateSuggestion()
            }
            
            Task {
                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.SUGGESTION_COLORS)
                
                if shouldSync {
                    await fetchColorsSuggestion()
                }
            }
        }.onChange(of: showCreationSheet, initial: true) {
            if showCreationSheet {
                newListEmoji = String.randomEmoji()
                
                Task {
                    await fetchListTemplateSuggestion()
                }
            }
        }
    }
    
    
}

#Preview {
    @Previewable @StateObject var ixApiClient = IxApiClient()
    @Previewable @StateObject var errorService = ErrorStateService()
    @Previewable @StateObject var navigationManager = NavigationManager()

    ListsTabView()
        .environmentObject(ixApiClient)
        .environmentObject(errorService)
        .environmentObject(navigationManager)
}
