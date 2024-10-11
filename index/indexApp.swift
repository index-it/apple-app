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
    
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var authNavigationManager = AuthNavigationManager()
    @StateObject private var ixApiClient = IxApiClient()
    
    @AppStorage("user") var user: User?
    
    @State private var authStatus: AuthStatus = .Loading
    
    func handleNewNetworkAuthStatus(networkAuthStatus: AuthStatus) {
        switch networkAuthStatus {
        case .Loading:
            Self.log.debug("network client authentication loading")
        case .Unauthenticated:
            Self.log.debug("network client unauthenticated")
            self.user = nil
        case let .Authenticated(user: networkUser):
            Self.log.debug("network client authenticated - id: \(networkUser.id) - email: \(networkUser.email)")
            self.user = networkUser
            /*
             TODO:
             - connect to websockets
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
            navigationManager.clear()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(authStatus: $authStatus)
                .environmentObject(navigationManager)
                .environmentObject(authNavigationManager)
                .environmentObject(ixApiClient)
                .onReceive(ixApiClient.$authenticationStatus) { newValue in
                    handleNewNetworkAuthStatus(networkAuthStatus: newValue)
                }
                .onChange(of: user, initial: true) { _, newValue in
                    handleNewAppStorageUser(user: newValue)
                }.onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
