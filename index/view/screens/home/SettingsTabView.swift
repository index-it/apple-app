//
//  AccountTab.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import RevenueCat
import IxCoreKit

struct SettingsTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @EnvironmentObject private var navigationManager: NavigationManager

    @AppStorage(AppStorageKeys.loggedInUser) var user: User?
    
    @State private var showOnboarding = false
    @State private var showPaywall = false
    
    @State private var manageSubscriptionLoading: Bool = false

    private func manageSubscriptions() {
        manageSubscriptionLoading = true
        
        Purchases.shared.getCustomerInfo { customer, error in
            manageSubscriptionLoading = false
            if let error = error {
                errorService.insert(.localizedError(title: "Couldn't open subscriptions page", error: error))
                return
            }
            
            if let customer = customer {
                if let url = customer.managementURL {
                    openURL(url)
                }
            }
        }
    }
    
    var body: some View {
        Settings
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView {
                    showPaywall = false
                }
            }
        
    }
    
    private var Settings: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    if let user = user, !user.has_pro {
                        getProView
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.top, 12)
                    }
                    
                    Section {
                        Button {
                            navigationManager.push(.accountSettings)
                        } label: {
                            HStack {
                                Label("Account", systemImage: "person.fill")
                                    .labelStyle(ColorfulIconLabelStyle(color: .accentColor))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let user = user, user.has_pro {
                            Button {
                                navigationManager.push(.proSettings)
                            } label: {
                                HStack {
                                    Label("Pro", systemImage: "crown.fill")
                                        .labelStyle(ColorfulIconLabelStyle(color: .purple))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.forward")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
                        
                        Button {
                            navigationManager.push(.about)
                        } label: {
                            HStack {
                                Label("About & Feedback", systemImage: "heart.fill")
                                    .labelStyle(ColorfulIconLabelStyle(color: .orange))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
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
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Settings")
        }
    }
    
    var getProView: some View {
        Button {
            showPaywall = true
        } label: {
            ZStack {
                HStack {
                    HStack(spacing: 24) {
                        Image(systemName: "bolt.circle.fill")
                            .scaleEffect(1.75)
                            .opacity(0.8)
                        
                        VStack(alignment: .leading) {
                            Text("Index Pro")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Unlock all features")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Upgrade")
                            .fontWeight(.bold)
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background {
                                Color(red: 25/255, green: 65/255, blue: 45/255)
                                    .brightness(0.2)
                                    .saturation(0.7)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background {
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color(red: 15/255, green: 40/255, blue: 25/255), // Darker green
                                Color(red: 25/255, green: 65/255, blue: 45/255)  // Lighter green
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
    
    var currentlySubscribedCardView: some View {
        ZStack {
            HStack {
                HStack(spacing: 24) {
                    Image(systemName: "bolt.circle.fill")
                        .scaleEffect(1.75)
                        .opacity(0.8)
                    
                    VStack(alignment: .leading) {
                        Text("Pro enabled")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Thank you for supporting the app :)")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background {
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            Color(red: 15/255, green: 40/255, blue: 25/255), // Darker green
                            Color(red: 25/255, green: 65/255, blue: 45/255)  // Lighter green
                        ]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }.foregroundStyle(.white)
    }
}

#Preview {
    SettingsTabView()
}
