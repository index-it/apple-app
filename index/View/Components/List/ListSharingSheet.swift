//
//  ListSharingSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/11/24.
//

import SwiftUI
import IxCoreKit

struct ListSharingSheet: View {
    @State private var navPath: [ListShareSheetNavigationRoute] = []
    @State private var showAddUserDialog = false
    @State private var addUserEmail = ""
    @State private var addUserEditor = false
    @State private var selectedUser: IxListSingleUserAccessInfo? = nil
    @State private var showUserActions = false
    
    private var isInviteEmailValid: Bool {
        addUserEmail.contains("@") && addUserEmail.contains(".") && addUserEmail.count >= 5
    }
    
    @AppStorage(AppStorageKeys.loggedInUser) private var user: User?
    @State private var showPaywall = false
    
    private var listId: String
    @State private var isPublic: Bool
    @Binding private var showSheet: Bool
    @Binding private var showUserInvitationSuccessAlert: Bool
    @Binding private var loadingPublic: Bool
    @Binding private var loadingUsers: Bool
    @Binding private var loadingUserInvite: Bool
    @Binding private var loadingUserEditOrDelete: String?
    @Binding private var usersWithAccess: [IxListSingleUserAccessInfo]
    
    private var onPublicChange: (Bool) -> Void
    private var onUserInvite: (String, Bool) -> Void
    private var onEditUserPermissions: (String, Bool) -> Void
    private var onUserRevoke: (String) -> Void
    

    init(
        showSheet: Binding<Bool>,
        showUserInvitationSuccessAlert: Binding<Bool>,
        loadingPublic: Binding<Bool>,
        loadingUsers: Binding<Bool>,
        loadingUserInvite: Binding<Bool>,
        loadingUserEditOrDelete: Binding<String?>,
        listId: String,
        isPublic: Bool,
        usersWithAccess: Binding<[IxListSingleUserAccessInfo]>,
        onPublicChange: @escaping (Bool) -> Void,
        onUserInvite: @escaping (String, Bool) -> Void,
        onUserEditEditorPermission: @escaping (String, Bool) -> Void,
        onUserRevokeAccess: @escaping (String) -> Void
    ) {
        self._showSheet = showSheet
        self._showUserInvitationSuccessAlert = showUserInvitationSuccessAlert
        self._loadingPublic = loadingPublic
        self._loadingUsers = loadingUsers
        self._loadingUserInvite = loadingUserInvite
        self._loadingUserEditOrDelete = loadingUserEditOrDelete
        self.listId = listId
        self.isPublic = isPublic
        self._usersWithAccess = usersWithAccess
        self.onPublicChange = onPublicChange
        self.onUserInvite = onUserInvite
        self.onEditUserPermissions = onUserEditEditorPermission
        self.onUserRevoke = onUserRevokeAccess
    }
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ShareSheet
                .navigationDestination(for: ListShareSheetNavigationRoute.self) { route in
                    switch route {
                    case .inviteUser:
                        InviteSheet
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
        .paywallCover(isPresented: $showPaywall)

    }
    
    var ShareSheet: some View {
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
                                showPaywall = true
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
                            ForEach(usersWithAccess.filter({ $0.editor }), id: \.userId) { user in
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
                            ForEach(usersWithAccess.filter({ !$0.editor }), id: \.userId) { user in
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
        .navigationTitle("Sharing")
        .navigationSubtitle(loadingUsers ? "Loading users..." : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                ShareLink(item: URL(string: IxUniversalLinks.list(listId))!) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onChange(of: isPublic) { _, new in
            onPublicChange(new)
        }
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
    }
    
    var InviteSheet: some View {
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
            }.frame(maxHeight: 250)
            
            Button {
                onUserInvite(addUserEmail, addUserEditor)
                navPath.removeLast()
            } label: {
                HStack {
                    Label("Send invite", systemImage: "paperplane")
                }.frame(maxWidth: .infinity)
                    
            }.buttonStyle(.borderedProminent)
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
    ListSharingSheet(
        showSheet: .constant(true),
        showUserInvitationSuccessAlert: .constant(false),
        loadingPublic: .constant(false),
        loadingUsers: .constant(false),
        loadingUserInvite: .constant(false),
        loadingUserEditOrDelete: .constant(nil),
        listId: "",
        isPublic: false,
        usersWithAccess: .constant([])) { _ in
            
        } onUserInvite: { _, _ in
            
        } onUserEditEditorPermission: { _, _ in
            
        } onUserRevokeAccess: { _ in
            
        }
}
