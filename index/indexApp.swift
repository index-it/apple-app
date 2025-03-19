//
//  indexApp.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/09/24.
//

import os
import SwiftUI
import SwiftData
import GoogleSignIn
import FirebaseMessaging
import RevenueCat

@main
struct indexApp: App {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "index-app-entrypoint")
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // managers
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var authNavigationManager = AuthNavigationManager()
    @StateObject private var errorService = ErrorStateService()
    
    // clients
    private var modelContainer: ModelContainer
    @StateObject private var ixApiClient: IxApiClient
    private var ixWebsocketClient: IxWebsocketClient
    
    // auth & user
    @AppStorage(AppStorageKeys.logged_in_user) var user: User?
    @State private var authStatus: AuthStatus = .Loading
    
    // webview
    @State private var presentingSafariView = false
    @State private var urlToOpen: URL?
    
    init() {
        let apiClient = IxApiClient()
        self._ixApiClient = StateObject(wrappedValue: apiClient)
        
        self.modelContainer = ModelContainerProvider.shared
        
        let websocketEventHandler = IxWebsocketEventHandler(ixApiClient: apiClient, modelContext: modelContainer.mainContext)
        let websocketClient = IxWebsocketClient(ixWebsocketEventHandler: websocketEventHandler)
        self.ixWebsocketClient = websocketClient
    }
    
    func handleNewNetworkAuthStatus(networkAuthStatus: AuthStatus) {
        switch networkAuthStatus {
        case .Loading:
            Self.log.debug("network client authentication loading")
        case .Unauthenticated:
            Self.log.debug("network client unauthenticated")
            
            self.user = nil
            
            DispatchQueue.main.async {
                do {
                    try modelContainer.mainContext.transaction {
                        try modelContainer.mainContext.delete(model: IxList.self)
                        try modelContainer.mainContext.delete(model: IxListCategory.self)
                        try modelContainer.mainContext.delete(model: IxListItem.self)
                        try modelContainer.mainContext.delete(model: IxTask.self)
                    }
                } catch {}
            }
            
            SyncRegister.shared.resetState()
            
            ixWebsocketClient.disconnectFromWebsocket()
        case let .Authenticated(user: networkUser):
            Self.log.debug("network client authenticated - id: \(networkUser.id) - email: \(networkUser.email)")
            self.user = networkUser
            
            SyncRegister.shared.resetState()
            
            ixWebsocketClient.connectAndListenToWebsocket()
            
            Task {
                do {
                    let firebaseMessagingToken = try await Messaging.messaging().token()
                    try await self.ixApiClient.sendNotificationRegistrationToken(token: firebaseMessagingToken)
                } catch {
                    print("Failed sending firebase messaging token to server: \(error)")
                }
            }
            
            Task {
                do {
                    let _ = try await Purchases.shared.logIn(networkUser.id)
                } catch {
                    print("Failed logging in user in revenue cat: \(error)")
                }
            }
        }
    }
    
    func handleNewAppStorageUser(user: User?) {
        guard let nonNilUser = user else {
            Self.log.debug("received nil user from AppStorage, setting the authStatus to Unauthenticated")
            DispatchQueue.main.async {
                authStatus = .Unauthenticated
                navigationManager.clear()
            }
            return
        }
        
        Self.log.debug("received user from AppStorage - id: \(nonNilUser.id) - email: \(nonNilUser.email)")
        
        DispatchQueue.main.async {
            authStatus = .Authenticated(user: nonNilUser)
            authNavigationManager.clear()
            navigationManager.clear()
        }
    }
    
    
    func handleIncomingURL(_ url: URL) {
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }
        
        handleInAppNavigation(url)
    }
    
    func handleInAppNavigation(_ url: URL) {
        if url.host() != "web.index-it.app" {
            return
        }
        
        // Extract the path components, ignoring the domain for Universal Links
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard pathComponents.count >= 1 else { return }
        
        // Rest of your URL parsing logic remains the same
        let section = pathComponents[0]
        
        switch section {
        case "create-item":
            navigationManager.navigateToTab(.lists, showCreateSheet: true)
        case "create-task":
            navigationManager.navigateToTab(.tasks, showCreateSheet: true)
        case "lists":
            if let listId = pathComponents[safe: 1] {
                print(listId)
                navigationManager.push(navigationRoute: .listRoute(listId: listId))
            } else {
                navigationManager.navigateToTab(.lists)
            }
        case "tasks":
            navigationManager.navigateToTab(.tasks)
        case "settings":
            navigationManager.navigateToTab(.settings)
        default:
            return
        }
    }
    
    var body: some Scene {
        WindowGroup {
//            MainView(authStatus: $authStatus)
            PaywallView() {}
                .environmentObject(navigationManager)
                .environmentObject(authNavigationManager)
                .environmentObject(ixApiClient)
                .environmentObject(errorService)
                .modelContainer(modelContainer)
                .onReceive(ixApiClient.$authenticationStatus) { newValue in
                    handleNewNetworkAuthStatus(networkAuthStatus: newValue)
                }
                .onChange(of: user, initial: true) { _, newValue in
                    handleNewAppStorageUser(user: newValue)
                }
                .alertPresentationWindow(service: errorService)
                .onOpenURL(perform: { url in
                    handleIncomingURL(url)
                })
                .environment(\.openURL, OpenURLAction { url in
                    self.urlToOpen = url
                    self.presentingSafariView = true
                    return .handled
                })
                .sheet(isPresented: $presentingSafariView, onDismiss: { self.urlToOpen = nil }) { [urlToOpen] in
                    if let url = urlToOpen {
                        SafariView(url: url)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToTasks)) { notification in
                    navigationManager.navigateToTab(.tasks)
                }
        }
    }
}
