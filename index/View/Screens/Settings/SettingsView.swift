//
//  SettingsView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import IxCoreKit
import RevenueCat
import SwiftUI
import DynamicColor

struct SettingsView: View {
    @Environment(IxNavigator.self) private var navigator
    @Environment(CalendarManager.self) private var calendarManager
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    @Environment(\.showPaywall) private var showPaywall
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @Environment(\.showError) private var showError
    
    @AppStorage(AppStorageKeys.loggedInUser) var user: User?
    @AppStorage(AppStorageKeys.Tasks.showCalendarEvents) var showCalendarEvents: Bool = AppStorageKeys.Defaults.showCalendarEvents
    
    @State private var showOnboarding = false
    
    @State private var manageSubscriptionLoading: Bool = false
    
    private func manageSubscriptions() {
        manageSubscriptionLoading = true
        
        Purchases.shared.getCustomerInfo { customer, error in
            manageSubscriptionLoading = false
            if let error = error {
                showError(.localizedError(title: "Couldn't open subscriptions page", error: error))
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
            .onChange(of: showCalendarEvents) { _, newValue in
                if newValue && !calendarManager.permitted {
                    Task {
                        let accepted = await calendarManager.requestPermissions()
                        if !accepted {
                            showCalendarEvents = false
                            showError(
                                .customMessage(
                                    title: "Enable Calendar access",
                                    message: "Go into Settings > Apps > Index and enable calendar access to show calendar events in the Tasks list.",
                                    buttons: [.init(title: "Open settings", isDestructive: false, action: {
                                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                        if UIApplication.shared.canOpenURL(url) {
                                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                        }
                                    })]
                                )
                            )
                        }
                    }
                }
            }
    }
    
    private var Settings: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    if let user = user, !user.has_pro, IxFlags.Pro.enabled {
                        getProView
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.top, 12)
                    }
                    
                    Section {
                        Button {
                            navigator.push(.accountSettings)
                        } label: {
                            HStack {
                                Label("Account", systemImage: "person.fill")
                                    .labelStyle(ListLabelStyle(color: .indigo))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // TODO: Add when Pro is back
                        //                        if let user = user, user.has_pro {
                        //
                        //                        }
                        
                        Button {
                            navigator.push(.proSettings)
                        } label: {
                            HStack {
                                Label("Pro", systemImage: "crown.fill")
                                    .labelStyle(ListLabelStyle(color: .purple))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Section {
                        Toggle(isOn: $showCalendarEvents) {
                            Label("Show calendar events", systemImage: "calendar")
                                .labelStyle(ListLabelStyle(color: .black))
                        }
                        
                        if showCalendarEvents {
                            Button {
                                navigator.push(.calendarSettings)
                            } label: {
                                HStack {
                                    Label("Configure Calendars", systemImage: "filemenu.and.selection")
                                        .labelStyle(ListLabelStyle(color: .black))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.forward")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Tasks Behaviour")
                    } footer: {
                        if showCalendarEvents {
                            Text("Calendar Events will be displayed in the Tasks list.")
                        }
                    }
                    
                    Section(header: Text("Support and Feedback")) {
                        Button(action: {
                            showOnboarding = true
                        }) {
                            Label("Show Guide", systemImage: "book.closed.fill")
                                .labelStyle(ListLabelStyle(color: .pink))
                        }.tint(.primary)
                        
                        Button {
                            EmailHelper.promptEmail()
                        } label: {
                            Label(title: {
                                Text("Contact")
                                    .foregroundStyle(Color.primary)
                            }, icon: {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(Color.white)
                            })
                            .labelStyle(ListLabelStyle(color: .cyan))
                        }
                        
                        Button {
                            navigator.push(.about)
                        } label: {
                            HStack {
                                Label("About & Feedback", systemImage: "heart.fill")
                                    .labelStyle(ListLabelStyle(color: .yellow))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.forward")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    aboutSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.automatic)
        .navigationTitle("Settings")
    }
    
    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://giuliopime.dev")!) {
                HStack {
                    Label(title: {
                        Text("Craftsman")
                            .foregroundStyle(Color.primary)
                    }, icon: {
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(Color.primary)
                    })
                    .labelStyle(ListLabelStyle(color: Color.systemBackgroundSecondary))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.gray)
                }
            }
            
            Link(destination: URL(string: "https://index-it.app/privacy")!) {
                HStack {
                    Label(title: {
                        Text("Privacy Policy")
                            .foregroundStyle(Color.primary)
                    }, icon: {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.primary)
                    })
                    .labelStyle(ListLabelStyle(color: Color.systemBackgroundSecondary))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.gray)
                }
            }
            
            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!) {
                HStack {
                    Label(title: {
                        Text("Terms Of Use")
                            .foregroundStyle(Color.primary)
                    }, icon: {
                        Image(systemName: "signature")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.primary)
                    })
                    .labelStyle(ListLabelStyle(color: Color.systemBackgroundSecondary))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.gray)
                }
            }
        } header: {
            Text("About")
        }
    }
    
    var getProView: some View {
        Button {
            showPaywall()
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
                        showPaywall()
                    } label: {
                        Text("Upgrade")
                            .fontWeight(.bold)
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background {
                                Color(red: 25 / 255, green: 65 / 255, blue: 45 / 255)
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
                                Color(red: 15 / 255, green: 40 / 255, blue: 25 / 255), // Darker green
                                Color(red: 25 / 255, green: 65 / 255, blue: 45 / 255), // Lighter green
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
                            Color(red: 15 / 255, green: 40 / 255, blue: 25 / 255), // Darker green
                            Color(red: 25 / 255, green: 65 / 255, blue: 45 / 255), // Lighter green
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
    @Previewable @State var navigator = IxNavigator()
    @Previewable @State var calendarManager = CalendarManager()
    @Previewable @State var ixApiClient = IxApiClient { _ in }
    
    NavigationView {
        SettingsView()
            .environment(navigator)
            .environment(calendarManager)
            .environment(\.ixApiClient, ixApiClient)
    }
}
