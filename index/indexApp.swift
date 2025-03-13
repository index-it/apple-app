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

@main
struct indexApp: App {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "index-app-entrypoint")
    
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
        
        self.modelContainer = ModelContainerProvider.get()
        
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
            /*
             TODO:
             - send notification token to backend
             - login revenue cat
             */
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
    
    var body: some Scene {
        WindowGroup {
            MainView(authStatus: $authStatus)
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
                }.onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .alertPresentationWindow(service: errorService)
                .environment(\.openURL, OpenURLAction { url in
                    self.urlToOpen = url
                    self.presentingSafariView = true
                    return .handled
                })
                .sheet(isPresented: $presentingSafariView, onDismiss: {
                    self.urlToOpen = nil
                }) {
                    if let url = urlToOpen {
                        SafariView(url: url)
                    }
                }
        }
    }
}
