//
//  AccountView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/02/25.
//

import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(AppStorageKeys.logged_in_user) var user: User?
    
    @State private var showChangePasswordAlert = false
    @State private var newPassword = ""
    @State private var newPasswordRepeat = ""
    
    private func logout() async {
        do {
            try await ixApiClient.logout()
        } catch {
            
        }
    }
    
    private func changePassword(newPassword: String) async {
        do {
            try await ixApiClient.changePassword(newPassword: newPassword)
        } catch {
            errorService.insert(.localizedError(title: "Error changing password", error: error))
        }
    }
    
    private func deleteAccount() async {
        do {
            try await ixApiClient.deleteLoggedInUser()
        } catch {
            errorService.insert(.localizedError(title: "Error deleting account", error: error))
        }
    }
    
    private var isNewPasswordValid: Bool {
        newPassword == newPasswordRepeat && (8...100).contains(newPassword.count) && newPassword.wholeMatch(of: /(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*$/) != nil
    }
    
    @State private var showLogoutDialog = false
    @State private var showDeleteAccountAlert = false
    @State private var deleteAccountGoodbyeText = ""
    
    private var isGoodbyeTextValid: Bool {
        deleteAccountGoodbyeText == "GOODBYE"
    }
    
    var body: some View {
        contentView
            .alert("Change Password", isPresented: $showChangePasswordAlert, actions: {
                SecureField("Enter new password", text: $newPassword)
                SecureField("Repeat password", text: $newPasswordRepeat)
                
                Button("Save") {
                    Task {
                        await changePassword(newPassword: newPassword)
                    }
                }.disabled(!isNewPasswordValid)
                
                Button("Cancel", role: .cancel, action: {})
            }, message: {
                Text("The password must be between 8 and 100 characters, and contain a lowercase letter, an uppercase one, and a number.")
            })
            .confirmationDialog("Logout", isPresented: $showLogoutDialog) {
                Button("Logout", role: .destructive) {
                    dismiss()
                    navigationManager.clear()
                    Task {
                        await logout()
                    }
                }
            }
            .alert("Delete account", isPresented: $showDeleteAccountAlert, actions: {
                TextField("Type 'GOODBYE'", text: $deleteAccountGoodbyeText)
                
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }.disabled(!isGoodbyeTextValid)
            }, message: {
                Text("Are you sure you want to delete your account?\n**This action is permanent**, all your data will be wiped out immediately and you won't be able to restore it!")
            })
    }
    
    private var contentView: some View {
        List {
            VStack {
                Text("Currently logged in as")
                
                Text(user?.email ?? "Loading...")
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
            }.padding()
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            
            Section {
                Button(action: {
                    showChangePasswordAlert = true
                }) {
                    Text("Change password")
                }
                
                Button(action: {
                    showLogoutDialog = true
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    Text("Delete account")
                        .foregroundColor(.red)
                }
            }
        }.navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Account")
    }
}

#Preview {
    AccountSettingsView()
}
