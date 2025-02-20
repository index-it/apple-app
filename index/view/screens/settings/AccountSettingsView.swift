//
//  AccountView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/02/25.
//

import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var userEmail: String
    var onChangePassword: (_ newPassword: String) -> ()
    var onLogout: () -> ()
    var onDeleteAccount: () -> ()
    
    @State private var showChangePasswordAlert = false
    @State private var newPassword = ""
    @State private var newPasswordRepeat = ""
    
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
                    onChangePassword(newPassword)
                }.disabled(!isNewPasswordValid)
                
                Button("Cancel", role: .cancel, action: {})
            }, message: {
                Text("The password must be between 8 and 100 characters, and contain a lowercase letter, an uppercase one, and a number.")
            })
            .confirmationDialog("Logout", isPresented: $showLogoutDialog) {
                Button("Logout", role: .destructive) {
                    dismiss()
                    dismiss()
                    onLogout()
                }
            }
            .alert("Delete account", isPresented: $showDeleteAccountAlert, actions: {
                TextField("Type 'GOODBYE'", text: $deleteAccountGoodbyeText)
                
                Button("Delete", role: .destructive) {
                    onDeleteAccount()
                }.disabled(!isGoodbyeTextValid)
            }, message: {
                Text("Are you sure you want to delete your account?\n**This action is permanent**, all your data will be wiped out immediately and you won't be able to restore it!")
            })
    }
    
    private var contentView: some View {
        List {
            VStack {
                Text("Currently logged in as")
                
                Text(userEmail)
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
    AccountSettingsView(userEmail: "giuliopime@gmail.com") { _ in
        
    } onLogout: {
        
    } onDeleteAccount: {
            
    }

}
