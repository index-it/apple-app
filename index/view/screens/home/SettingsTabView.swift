//
//  AccountTab.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    
    @AppStorage("user") var user: User?
    
    @State private var showOnboarding = false
    
    private func logout() async {
        do {
            try await ixApiClient.logout()
        } catch {
            
        }
    }
    
    private func changePassword(newPassword: String) async {
        do {
            try await ixApiClient.changePassword(newPassword: newPassword)
        } catch IxApiClientError.InvalidData {
            
        } catch {
            
        }
    }
    
    private func deleteAccount() async {
        do {
            // TODO: Uncomment on release
            // try await ixApiClient.deleteLoggedInUser()
        } catch {
            
        }
    }
    
    var body: some View {
        Settings
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                }
            }
        
    }
    
    private var Settings: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(
                        destination: {
                            AccountSettingsView(
                                userEmail: user?.email ?? "Loading...",
                                onChangePassword: { newPassword in
                                    Task {
                                        await changePassword(newPassword: newPassword)
                                    }
                                },
                                onLogout: {
                                    Task {
                                        await logout()
                                    }
                                },
                                onDeleteAccount: {
                                    Task {
                                        await deleteAccount()
                                    }
                                })
                        }) {
                        Label("Account", systemImage: "person.fill")
                            .labelStyle(ColorfulIconLabelStyle(color: .accentColor))
                    }
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Label("Show onboarding", systemImage: "signpost.right.fill")
                            .labelStyle(ColorfulIconLabelStyle(color: .green))
                    }.tint(.primary)
                }
                
                Section(header: Text("SUPPORT AND FEEDBACK")) {
                    Link(destination: URL(string: "https://index-it.app/support")!) {
                        Label("Support", systemImage: "lifepreserver.fill")
                            .labelStyle(ColorfulIconLabelStyle(color: .red))
                    }.tint(.primary)
                    Link(destination: URL(string: "https://apps.apple.com/TODO")!) {
                        Label("Rate on the App Store", systemImage: "star.fill")
                            .labelStyle(ColorfulIconLabelStyle(color: .yellow))
                    }.tint(.primary) // TODO
                }
                
                Section(header: Text("ABOUT")) {
                    Link(destination: URL(string: "https://index-it.app/privacy")!) {
                        Label(title: {
                            Text("Privacy")
                        }, icon: {
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.gray)
                        })
                    }.tint(.primary)
                    Link(destination: URL(string: "https://apps.apple.com/TODO")!) {
                        Label(title: {
                            Text("Terms of service")
                        }, icon: {
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.gray)
                        })
                    }.tint(.primary)
                    Link(destination: URL(string: "https://giuliopime.dev")!) {
                        Label(title: {
                            Text("About the developer")
                        }, icon: {
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.gray)
                        })
                    }.tint(.primary)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTabView()
}
