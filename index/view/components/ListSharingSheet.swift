//
//  ListSharingSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/11/24.
//

import SwiftUI

struct ListSharingSheet: View {
    @State private var navPath: [ListShareSheetNavigationRoute] = []
    @State private var showAddUserDialog = false
    @State private var addUserEmail = ""
    @State private var addUserEditor = false
    @State private var selectedUser: IxListSingleUserAccessInfo? = nil
    @State private var showUserActions = false
    
    @Binding private var showSheet: Bool
    @State private var isPublic: Bool
    @Binding private var usersWithAccess: [IxListSingleUserAccessInfo]
    
    private var onPublicChange: (Bool) -> Void
    

    init(
        showSheet: Binding<Bool>,
        isPublic: Bool,
        usersWithAccess: Binding<[IxListSingleUserAccessInfo]>,
        onPublicChange: @escaping (Bool) -> Void
    ) {
        self._showSheet = showSheet
        self.isPublic = isPublic
        self._usersWithAccess = usersWithAccess
        self.onPublicChange = onPublicChange
    }
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ShareSheet
                .navigationDestination(for: ListShareSheetNavigationRoute.self) { route in
                    switch route {
                    case .InviteUser:
                        InviteSheet
                    case .EditUser:
                        EditSheet
                    }
                }
        }
    }
    
    var ShareSheet: some View {
        VStack {
            Form {
                Section {
                    Toggle("Public list", isOn: $isPublic)
                } footer: {
                    Text("By making this list public it will be accessible by anyone, but only you will be able to edit it")
                }
                
                List {
                    Section {
                        if usersWithAccess.filter({ $0.editor }).isEmpty {
                            Text("No users with edit permissions")
                        } else {
                            ForEach(usersWithAccess.filter({ $0.editor }), id: \.user_id) { user in
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
                            navPath.append(.InviteUser)
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
                            ForEach(usersWithAccess.filter({ !$0.editor }), id: \.user_id) { user in
                                Button {
                                    selectedUser = user
                                    showUserActions = true
                                } label: {
                                    NavigationLink(user.email, destination: EmptyView())
                                }.foregroundStyle(Color(uiColor: .label))
                            }
                        }
                        
                        Button("Invite", systemImage: "plus") {
                            addUserEditor = false
                            navPath.append(.InviteUser)
                        }
                    } header: {
                        Text("Viewers")
                    } footer: {
                        Text("Viewers can only view the contents of the list without modifing anything, click to show actions")
                    }
                }
            }
        }.navigationTitle("Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: isPublic) { _, new in
                onPublicChange(new)
            }
            .confirmationDialog("Manage user access", isPresented: $showUserActions) {
                Button(selectedUser?.editor ?? false ? "Revoke edit permissions" : "Make editor") {
                    
                }
                
                Button("Revoke access completely", role: .destructive) {
                    
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
            } label: {
                HStack {
                    Label("Send invite", systemImage: "paperplane")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            
        }.frame(maxHeight: .infinity, alignment: .top)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Invite user")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var EditSheet: some View {
        EmptyView()
    }
}

#Preview {
    @Previewable @State var show = true
    @Previewable @State var users: [IxListSingleUserAccessInfo] = [
        IxListSingleUserAccessInfo(user_id: "1", email: "giuliopime@gmail.com", editor: false)
    ]
    
    ListSharingSheet(showSheet: $show, isPublic: false, usersWithAccess: $users) { _ in
        
    }
}
