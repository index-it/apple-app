//
//  ListSharingSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/11/24.
//

import IxCoreKit
import SwiftUI

struct ListSharingSheet: View {
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.showToast) private var showToast
    @State private var navPath: [ListShareSheetNavigationRoute] = []
    @State private var addUserEmail = ""
    @State private var addUserEditor = false
    @State private var selectedUser: IxListSingleUserAccessInfo? = nil
    @State private var showUserActions = false
    
    @Binding private var inviteEditorConfig: EditorConfig<IxListInvite>
    @Binding private var inviteUrl: URL?

    private var isInviteEmailValid: Bool {
        addUserEmail.contains("@") && addUserEmail.contains(".") && addUserEmail.count >= 5
    }

    @AppStorage(AppStorageKeys.loggedInUser) private var user: User?

    private var listId: String
    @State private var isPublic: Bool
    @Binding private var showSheet: Bool
    @Binding private var showUserInvitationSuccessAlert: Bool
    @Binding private var loadingPublic: Bool
    @Binding private var loadingUsers: Bool
    @Binding private var loadingUserInvite: Bool
    @Binding private var loadingUserEditOrDelete: String?
    @Binding private var usersWithAccess: [IxListSingleUserAccessInfo]
    @Binding private var activeInvites: [IxListInvite]

    private var onPublicChange: (Bool) -> Void
    private var onCreateInvite: () -> Void
    private var onDeleteInvite: (String) -> Void
    private var onUserInvite: (String, Bool) -> Void
    private var onEditUserPermissions: (String, Bool) -> Void
    private var onUserRevoke: (String) -> Void
    
    @State private var shareUrl: URL?

    init(
        showSheet: Binding<Bool>,
        showUserInvitationSuccessAlert: Binding<Bool>,
        loadingPublic: Binding<Bool>,
        loadingUsers: Binding<Bool>,
        loadingUserInvite: Binding<Bool>,
        loadingUserEditOrDelete: Binding<String?>,
        inviteEditorConfig: Binding<EditorConfig<IxListInvite>>,
        inviteUrl: Binding<URL?>,
        listId: String,
        isPublic: Bool,
        usersWithAccess: Binding<[IxListSingleUserAccessInfo]>,
        activeInvites: Binding<[IxListInvite]>,
        onPublicChange: @escaping (Bool) -> Void,
        onCreateInvite: @escaping () -> Void,
        onDeleteInvite: @escaping (String) -> Void,
        onUserInvite: @escaping (String, Bool) -> Void,
        onUserEditEditorPermission: @escaping (String, Bool) -> Void,
        onUserRevokeAccess: @escaping (String) -> Void
    ) {
        _showSheet = showSheet
        _showUserInvitationSuccessAlert = showUserInvitationSuccessAlert
        _loadingPublic = loadingPublic
        _loadingUsers = loadingUsers
        _loadingUserInvite = loadingUserInvite
        _loadingUserEditOrDelete = loadingUserEditOrDelete
        _inviteEditorConfig = inviteEditorConfig
        _inviteUrl = inviteUrl
        self.listId = listId
        self.isPublic = isPublic
        _usersWithAccess = usersWithAccess
        _activeInvites = activeInvites
        self.onPublicChange = onPublicChange
        self.onCreateInvite = onCreateInvite
        self.onDeleteInvite = onDeleteInvite
        self.onUserInvite = onUserInvite
        onEditUserPermissions = onUserEditEditorPermission
        onUserRevoke = onUserRevokeAccess
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
            isPresented: $showUserInvitationSuccessAlert
        ) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("An invitation email has been sent to \(addUserEmail). He will need to accept the invitation to \(addUserEditor ? "collaborate in " : "view") this list.")
        }
    }

    var ShareSheet: some View {
        ShareSheetContent
            .navigationTitle("Sharing")
            .navigationSubtitle(loadingUsers ? "Loading users..." : "")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $shareUrl) { shareUrl in
                ShareSheetView(item: shareUrl)
                    .presentationDetents([.medium, .large])
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button("Create invite link", systemImage: "link.badge.plus") {
                            inviteEditorConfig.reset()
                            navPath.append(.createInvite)
                        }
                        
                        Button("Share public link", systemImage: "globe") {
                            let hasPro = user?.has_pro == true

                            if hasPro {
                                if !isPublic {
                                    isPublic = true
                                }
                                
                                shareUrl = URL(string: IxUniversalLinks.list(listId))!
                            } else {
                                showPaywall()
                            }
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                
                if !activeInvites.isEmpty {
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
                    get: { inviteUrl != nil },
                    set: { newValue in inviteUrl = nil }
                ),
                actions: {
                    Button {
                        UIPasteboard.general.url = inviteUrl
                        showToast("Invite copied", systemImage: "document.on.document")
                    } label: {
                        Label("Copy", systemImage: "document.on.document")
                    }
                    
                    Button {
                        shareUrl = inviteUrl
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
                        onEditUserPermissions(selectedUser.email, !selectedUser.editor)
                    }
                }

                Button("Revoke access completely", role: .destructive) {
                    if let selectedUser {
                        onUserRevoke(selectedUser.userId)
                    }
                }
            }
            .onChange(of: isPublic) { _, new in
                onPublicChange(new)
            }
            .onChange(of: activeInvites) { _, new in
                if new.isEmpty && navPath.last == .viewActiveInvites {
                    navPath.removeLast()
                }
            }
    }
    
    var ShareSheetContent: some View {
        VStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { isPublic },
                        set: { newValue in
                            let hasPro = user?.has_pro == true

                            if hasPro {
                                isPublic = newValue
                            } else {
                                showPaywall()
                            }
                        }
                    )) {
                        HStack {
                            if loadingPublic {
                                ProgressView()
                            }

                            Text("Public list")
                        }
                    }.disabled(loadingPublic)

                } footer: {
                    Text("By making this list public it will be accessible by anyone, but only you will be able to edit it")
                }

                List {
                    Section {
                        if usersWithAccess.filter({ $0.editor }).isEmpty {
                            Text("No users with edit permissions")
                        } else {
                            ForEach(usersWithAccess.filter { $0.editor }, id: \.userId) { user in
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
                        if usersWithAccess.filter({ !$0.editor }).isEmpty {
                            Text("No users with view permissions")
                        } else {
                            ForEach(usersWithAccess.filter { !$0.editor }, id: \.userId) { user in
                                Button {
                                    selectedUser = user
                                    showUserActions = true
                                } label: {
                                    HStack {
                                        if loadingUserEditOrDelete == user.userId {
                                            ProgressView()
                                        }

                                        NavigationLink(user.email, destination: EmptyView())
                                    }
                                }.foregroundStyle(Color(uiColor: .label))
                                    .disabled(loadingUserEditOrDelete == user.userId)
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
                    Toggle("Editor", isOn: $inviteEditorConfig.entity.editor)
                } header: {
                    Text("Permissions")
                }
                
                Section {
                    Toggle("Set max usage count", isOn: Binding(
                        get: {inviteEditorConfig.entity.maxUsages != nil },
                        set: { limitUsages in inviteEditorConfig.entity.maxUsages = (limitUsages ? 1 : nil) }
                    ))
                    
                    if inviteEditorConfig.entity.maxUsages != nil {
                        Stepper(
                            "Max usages: \(inviteEditorConfig.entity.maxUsages ?? 1)",
                            value: $inviteEditorConfig.entity.maxUsages ?? 1,
                            in: IxValidations.ListInvite.minMaxUsages...IxValidations.ListInvite.maxMaxUsages
                        )
                    }
                    
                    Toggle("Set expiration date", isOn: Binding(
                        get: {inviteEditorConfig.entity.expiresAt != nil },
                        set: { setExpiration in inviteEditorConfig.entity.expiresAt = (setExpiration ? Date.now.addingTimeInterval(DateHelper.oneDaySeconds) : nil) }
                    ))
                    
                    if inviteEditorConfig.entity.expiresAt != nil {
                        DatePicker(
                            selection: $inviteEditorConfig.entity.expiresAt ?? Date.now.addingTimeInterval(DateHelper.oneDaySeconds),
                            in: Date.now.addingTimeInterval(60)...
                        ) {
                            Text("Select date")
                        }.datePickerStyle(.compact)
                    }
                } header: {
                    Text("Restrict usage")
                }
                
                Section {
                    TextField("Description", text: $inviteEditorConfig.entity.description ?? "")
                } footer: {
                    Text("Optional description to remember the purpose of this invite")
                }
            }.frame(maxHeight: 420)
            
            Button {
                onCreateInvite()
                navPath.removeLast()
            } label: {
                HStack {
                    if inviteEditorConfig.loading {
                        ProgressView()
                    }
                    Label("Create invite", systemImage: "link.badge.plus")
                }.frame(maxWidth: .infinity)

            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding()
            .disabled(inviteEditorConfig.loading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Create invite link")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var ActiveInvitesSheet: some View {
        List {
            Section {
                ForEach(activeInvites) { invite in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text(invite.description ?? "No description provided")
                            
                            Text(
                                invite.expiresAt.map {
                                    "Expires at \(DateHelper.Formatters.dateTime.string(from: $0.toLocalDate()))"
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
                            onDeleteInvite(invite.id)
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
                onUserInvite(addUserEmail, addUserEditor)
                navPath.removeLast()
            } label: {
                HStack {
                    Label("Send invite", systemImage: "paperplane")
                }.frame(maxWidth: .infinity)
                
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding()
            .disabled(loadingUserInvite || !isInviteEmailValid)
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

#Preview {
    @Previewable @State var inviteEditorConfig = EditorConfig<IxListInvite>()
    @Previewable @State var inviteUrl: URL? = nil
    
    ListSharingSheet(
        showSheet: .constant(true),
        showUserInvitationSuccessAlert: .constant(false),
        loadingPublic: .constant(false),
        loadingUsers: .constant(false),
        loadingUserInvite: .constant(false),
        loadingUserEditOrDelete: .constant(nil),
        inviteEditorConfig: $inviteEditorConfig,
        inviteUrl: $inviteUrl,
        listId: "",
        isPublic: false,
        usersWithAccess: .constant([]),
        activeInvites: .constant([
            IxListInvite(id: "1", token: nil, listId: "1", editor: true, maxUsages: 2, description: "Some description", expiresAt: .now, createdAt: 0),
            IxListInvite(id: "2", token: nil, listId: "1", editor: false, maxUsages: 5, description: nil, expiresAt: .now, createdAt: 0),
            IxListInvite(id: "3", token: nil, listId: "1", editor: false, maxUsages: nil, description: "A really really really long description yay", expiresAt: nil, createdAt: 0)
        ])
    ) { _ in
    } onCreateInvite: {
        inviteUrl = URL(string: "https://google.com")!
    } onDeleteInvite: { _ in
    } onUserInvite: { _, _ in
    } onUserEditEditorPermission: { _, _ in
    } onUserRevokeAccess: { _ in
    }
}
