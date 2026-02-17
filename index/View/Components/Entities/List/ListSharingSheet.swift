//
//  ListSharingSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/11/24.
//

import IxCoreKit
import SwiftData
import SwiftUI

struct ListSharingSheet: View {
    @Query private var lists: [IxList]
    @State private var list: IxList? = nil
    
    var listId: String
    var onClose: () -> Void
    
    init(listId: String, onClose: @escaping () -> Void) {
        self.listId = listId
        self.onClose = onClose
        
        var listDescriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.id == listId
            }
        )
        listDescriptor.fetchLimit = 1
        _lists = Query(listDescriptor)
    }
    
    var body: some View {
        Group {
            if let list {
                ListSharingSheetView(list: list)
            } else {
                ProgressView()
            }
        }
        .onChange(of: lists, initial: true) { _, newLists in
            guard let newList = newLists.first else {
                onClose()
                return
            }

            list = newList
        }
    }
}

struct ListSharingSheetView: View {
    @Environment(\.modelContext) private var context
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @Environment(\.showError) private var showError
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.showToast) private var showToast
    
    @AppStorage(AppStorageKeys.loggedInUser) private var user: User?
    
    @State private var state = ListSharingState()
    @Bindable var list: IxList
   
    @State private var navPath: [ListShareSheetNavigationRoute] = []
    @State private var addUserEmail = ""
    @State private var addUserEditor = false
    @State private var selectedUser: IxListSingleUserAccessInfo? = nil
    @State private var showUserActions = false
    
    @State private var shareUrl: URL?

    private var isInviteEmailValid: Bool {
        addUserEmail.contains("@") && addUserEmail.contains(".") && addUserEmail.count >= 5
    }
    
    private func saveList(_ list: IxList) async throws {
        try context.transaction {
            context.insert(list)
        }

        try? await IxSystemIntegration.handleNewEntity(IxListEntity(list: list))
    }
    
    private func fetchUsers() async {
        do {
            state.loadingUsers = true
            defer { state.loadingUsers = false }
            state.usersWithAccess = try await ixApiClient.getListUsersWithAccess(id: list.id)
        } catch {
            showError(.localizedError(title: "Error fetching users", error: error))
        }
    }
    
    private func fetchInvites() async {
        do {
            state.activeInvites = try await ixApiClient.getListInvites(listId: list.id)
        } catch {
            showError(.localizedError(title: "Error fetching active invites", error: error))
        }
    }
    
    private func editListPublic(isPublic: Bool) async {
        do {
            state.loadingPublic = true
            defer { state.loadingPublic = false }

            let updated = try await ixApiClient.editList(
                id: list.id,
                name: list.name,
                icon: list.icon,
                color: list.color,
                archived: list.archived,
                is_public: isPublic
            )

            try await saveList(updated)
        } catch {
            showError(.localizedError(title: "Error updating list", error: error))
        }
    }
    
    private func inviteUser(email: String, editor: Bool) async {
        do {
            state.loadingUserInvite = true
            defer { state.loadingUserInvite = false }

            let updated = try await ixApiClient.inviteUserToList(
                listId: list.id,
                email: email,
                editor: editor
            )

            if let updated {
                try await saveList(updated)
            } else {
                state.showUserInvitationSuccessAlert = true
            }
        } catch {
            showError(.localizedError(title: "Error inviting user", error: error))
        }
    }
    
    private func editUserPermissions(email: String, editor: Bool) async {
        do {
            state.loadingUserEditOrRevokePermissions =
                state.usersWithAccess.first(where: { $0.email == email })?.userId

            let updated = try await ixApiClient.inviteUserToList(
                listId: list.id,
                email: email,
                editor: editor
            )

            if let updated {
                try await saveList(updated)
            }
            
            state.loadingUserEditOrRevokePermissions = nil

            await fetchUsers()
        } catch {
            state.loadingUserEditOrRevokePermissions = nil
            showError(.localizedError(title: "Error changing user permissions", error: error))
        }
    }
    
    private func revokeUserAccess(userId: String) async {
        do {
            state.loadingUserEditOrRevokePermissions = userId
            state.loadingUserEditOrRevokePermissions = nil

            let updated = try await ixApiClient.revokeListAccessFromUser(
                listId: list.id,
                userId: userId
            )

            try await saveList(updated)
            state.loadingUserEditOrRevokePermissions = nil
            await fetchUsers()
        } catch {
            state.loadingUserEditOrRevokePermissions = nil
            showError(.localizedError(title: "Error revoking user access", error: error))
        }
    }
    
    private func createInvite() async {
        do {
            state.inviteEditorConfig.loading = true
            defer { state.inviteEditorConfig.loading = false }

            let createData = try state.inviteEditorConfig.sanitizeAndValidate()

            let invite = try await ixApiClient.createListInvite(
                listId: list.id,
                editor: createData.editor,
                maxUsages: createData.maxUsages,
                expiresAt: createData.expiresAt,
                description: createData.description
            )

            state.inviteEditorConfig.isPresented = false

            if let token = invite.token,
               let url = URL(string: IxUniversalLinks.listInvite(token)) {
                state.inviteUrl = url
            } else {
                showError(.customMessage(
                    title: "Error creating invite",
                    message: "Unexpected server response."
                ))
            }
        } catch {
            showError(.localizedError(title: "Error creating invite", error: error))
        }
    }
    
    private func deleteInvite(_ inviteId: String) async {
        do {
            try await ixApiClient.deleteListInvite(
                listId: list.id,
                inviteId: inviteId
            )

            await fetchInvites()
        } catch {
            showError(.localizedError(title: "Error deleting invite", error: error))
        }
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ShareSheet
                .navigationDestination(for: ListShareSheetNavigationRoute.self) { route in
                    switch route {
                    case .viewActiveInvites:
                        ActiveInvitesSheet
                    case .createInvite:
                        InviteFormSheet
                    case .inviteUser:
                        InviteUserSheet
                    case .editUser:
                        EditSheet
                    }
                }
        }
        .alert(
            "Invitation sent",
            isPresented: $state.showUserInvitationSuccessAlert
        ) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("An invitation email has been sent to \(addUserEmail). He will need to accept the invitation to \(addUserEditor ? "collaborate in " : "view") this list.")
        }
        .onAppear {
            Task {
                await fetchUsers()
            }
            
            Task {
                await fetchInvites()
            }
        }
    }

    var ShareSheet: some View {
        ShareSheetContent
            .navigationTitle("Sharing")
            .navigationSubtitle(state.loadingUsers ? "Loading users..." : "")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $shareUrl) { shareUrl in
                ShareSheetView(item: shareUrl)
                    .presentationDetents([.medium, .large])
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button("Create invite link", systemImage: "link.badge.plus") {
                            state.inviteEditorConfig.reset()
                            navPath.append(.createInvite)
                        }

                        Button("Share public link", systemImage: "globe") {
                            Task { @MainActor in
                                let hasPro = user?.has_pro == true
                                
                                if hasPro {
                                    if !list.isPublic {
                                        await editListPublic(isPublic: true)
                                    }
                                    
                                    shareUrl = URL(string: IxUniversalLinks.list(list.id))!
                                } else {
                                    showPaywall()
                                }
                            }
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }

                if !state.activeInvites.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            navPath.append(.viewActiveInvites)
                        } label: {
                            Label("View active invites", systemImage: "tray.full")
                        }
                    }
                }
            }
            .alert(
                "Invite created",
                isPresented: Binding(
                    get: { state.inviteUrl != nil },
                    set: { _ in state.inviteUrl = nil }
                ),
                actions: {
                    Button {
                        UIPasteboard.general.url = state.inviteUrl
                        showToast("Invite copied", systemImage: "document.on.document")
                    } label: {
                        Label("Copy", systemImage: "document.on.document")
                    }

                    Button {
                        shareUrl = state.inviteUrl
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .keyboardShortcut(.defaultAction)
                },
                message: {
                    Text("The invite link for this list has been created, you can copy it or share it!\nOnce you close this you will not be able to copy the link anymore!")
                }
            )
            .alert("Manage user access", isPresented: $showUserActions) {
                Button(selectedUser?.editor ?? false ? "Revoke edit permissions" : "Make editor") {
                    if let selectedUser {
                        Task {
                            await editUserPermissions(email: selectedUser.email, editor: !selectedUser.editor)
                        }
                    }
                }

                Button("Revoke access completely", role: .destructive) {
                    if let selectedUser {
                        Task {
                            await revokeUserAccess(userId: selectedUser.userId)
                        }
                    }
                }
            }
            .onChange(of: state.activeInvites) { _, new in
                if new.isEmpty && navPath.last == .viewActiveInvites {
                    navPath.removeLast()
                }
            }
    }

    var ShareSheetContent: some View {
        VStack {
            Form {
                Section {
                    Toggle(
                        isOn: Binding(
                            get: {
                                list.isPublic
                            },
                            set: { newValue in
                                let hasPro = user?.has_pro == true
                                
                                if hasPro {
                                    Task { await editListPublic(isPublic: newValue) }
                                } else {
                                    showPaywall()
                                }
                            }
                        )
                    ) {
                        HStack {
                            if state.loadingPublic {
                                ProgressView()
                            }

                            Text("Public list")
                        }
                    }.disabled(state.loadingPublic)

                } footer: {
                    Text("By making this list public it will be accessible by anyone, but only you will be able to edit it")
                }

                List {
                    Section {
                        if state.usersWithAccess.filter({ $0.editor }).isEmpty {
                            Text("No users with edit permissions")
                        } else {
                            ForEach(state.usersWithAccess.filter { $0.editor }, id: \.userId) { user in
                                Button {
                                    selectedUser = user
                                    showUserActions = true
                                } label: {
                                    NavigationLink(user.email, destination: EmptyView())
                                }.foregroundStyle(Color(uiColor: .label))
                            }
                        }

                        Button("Invite", systemImage: "plus") {
                            addUserEditor = true
                            addUserEmail = ""
                            navPath.append(.inviteUser)
                        }
                    } header: {
                        Text("Editors")
                    } footer: {
                        Text("Editors are allowed to do anything inside the list but cannot delete it, click to show actions")
                    }

                    Section {
                        if state.usersWithAccess.filter({ !$0.editor }).isEmpty {
                            Text("No users with view permissions")
                        } else {
                            ForEach(state.usersWithAccess.filter { !$0.editor }, id: \.userId) { user in
                                Button {
                                    selectedUser = user
                                    showUserActions = true
                                } label: {
                                    HStack {
                                        if state.loadingUserEditOrRevokePermissions == user.userId {
                                            ProgressView()
                                        }

                                        NavigationLink(user.email, destination: EmptyView())
                                    }
                                }.foregroundStyle(Color(uiColor: .label))
                                    .disabled(state.loadingUserEditOrRevokePermissions == user.userId)
                            }
                        }

                        Button("Invite", systemImage: "plus") {
                            addUserEditor = false
                            addUserEmail = ""
                            navPath.append(.inviteUser)
                        }
                    } header: {
                        Text("Viewers")
                    } footer: {
                        Text("Viewers can only view the contents of the list without modifing anything, click to show actions")
                    }
                }
            }
        }
    }

    var InviteFormSheet: some View {
        VStack {
            Form {
                Section {
                    Toggle("Editor", isOn: $state.inviteEditorConfig.entity.editor)
                } header: {
                    Text("Permissions")
                }

                Section {
                    Toggle("Set max usage count", isOn: Binding(
                        get: { state.inviteEditorConfig.entity.maxUsages != nil },
                        set: { limitUsages in state.inviteEditorConfig.entity.maxUsages = (limitUsages ? 1 : nil) }
                    ))

                    if state.inviteEditorConfig.entity.maxUsages != nil {
                        Stepper(
                            "Max usages: \(state.inviteEditorConfig.entity.maxUsages ?? 1)",
                            value: $state.inviteEditorConfig.entity.maxUsages ?? 1,
                            in: IxValidations.ListInvite.minMaxUsages ... IxValidations.ListInvite.maxMaxUsages
                        )
                    }

                    Toggle("Set expiration date", isOn: Binding(
                        get: { state.inviteEditorConfig.entity.expiresAt != nil },
                        set: { setExpiration in state.inviteEditorConfig.entity.expiresAt = (setExpiration ? Date.now.addingTimeInterval(DateHelper.oneDaySeconds) : nil) }
                    ))

                    if state.inviteEditorConfig.entity.expiresAt != nil {
                        DatePicker(
                            selection: $state.inviteEditorConfig.entity.expiresAt ?? Date.now.addingTimeInterval(DateHelper.oneDaySeconds),
                            in: Date.now.addingTimeInterval(60)...
                        ) {
                            Text("Select date")
                        }.datePickerStyle(.compact)
                    }
                } header: {
                    Text("Restrict usage")
                }

                Section {
                    TextField("Description", text: $state.inviteEditorConfig.entity.description ?? "")
                } footer: {
                    Text("Optional description to remember the purpose of this invite")
                }
            }.frame(maxHeight: 420)

            Button {
                Task {
                    await createInvite()
                }
                navPath.removeLast()
            } label: {
                HStack {
                    if state.inviteEditorConfig.loading {
                        ProgressView()
                    }
                    Label("Create invite", systemImage: "link.badge.plus")
                }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding()
            .disabled(state.inviteEditorConfig.loading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Create invite link")
        .navigationBarTitleDisplayMode(.inline)
    }

    var ActiveInvitesSheet: some View {
        List {
            Section {
                ForEach($state.activeInvites, id: \.id) { $invite in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text(invite.description ?? "No description provided")

                            Text(
                                invite.expiresAt.map {
                                    "Expires at \(DateHelper.Formatters.dateTime.string(from: $0))"
                                } ?? "Never expires"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Text(
                            invite.maxUsages.map {
                                "\($0) usages left"
                            } ?? "Unlimited usages"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await deleteInvite(invite.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            } footer: {
                Text("Those are all the active invite links of this list, you can delete them by swiping left.\n\nUser specific invites are not shown here and are not deletable.")
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Active invites")
        .navigationBarTitleDisplayMode(.inline)
    }

    var InviteUserSheet: some View {
        VStack {
            Form {
                Section {
                    TextField("User email", text: $addUserEmail)
                } header: {
                    Text("Email")
                } footer: {
                    Text("The user will receive an email with a link to accept this invitation")
                }

                Section {
                    Toggle("Editor", isOn: $addUserEditor)
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("Editors are allowed to modify the content of the list, choose editors with care!")
                }
            }.frame(maxHeight: 270)

            Button {
                Task {
                    await inviteUser(email: addUserEmail, editor: addUserEditor)
                }
                navPath.removeLast()
            } label: {
                HStack {
                    Label("Send invite", systemImage: "paperplane")
                }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding()
            .disabled(state.loadingUserInvite || !isInviteEmailValid)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Invite user")
        .navigationBarTitleDisplayMode(.inline)
    }

    var EditSheet: some View {
        EmptyView()
    }
}
