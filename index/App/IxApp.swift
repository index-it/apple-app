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
import FirebaseCore
import FirebaseMessaging
import RevenueCat
import IxCoreKit

fileprivate let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppEntrypoint")

///
/// ## Authentication
///
/// **AuthenticationHelper**
/// Simple class that holds the status of network and local authentication values
/// We react to:
/// - network auth change: set new value to the @AppStorage user + perform the core operations of user authentication
/// - local auth change: update navigation, we want navigation to be driven by the local value because it's faster on app load
///
/// **Network authentication**
/// Network authentication source of truth is the api client.
/// We pass a callback to the client for auth change events, the callback simply sets the new status in the AuthenticationHelper
///
/// **Local authentication**
/// Local authentication source of truth is the @AppStorage user value
/// We react to its changes and simply sets the new status in the AuthenticationHelper
///
/// ## Navigation
/// We use two different classes to handle authentication
/// - authentication: we have a navigation manager just for the authentication flow
/// - standard: this handles all navigation for the signed in user
///
/// **Why?**
/// We need to detach the two things, as an example:
/// The user has never logged into the app, opens a link for a public index list.
/// We need to authenticate the user first, and then navigate him to that list authomatically.
///
/// Easier way to do this was simply having two navigation stacks, so we do not need to restore state back and forth after authenticating, which could be quite an hassle expecially since we would need to wire up the navigation and authentication managers.
@main
struct IxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authenticationHelper: AuthenticationHelper
    @AppStorage(AppStorageKeys.loggedInUser, store: UserDefaults(suiteName: IxIdentifiers.APP_GROUP)!) private var user: User?
    
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var authNavigationManager = AuthNavigationManager()
    @StateObject private var errorService = ErrorStateService()
    
    private var modelContainer: ModelContainer
    private var ixApiClient: IxApiClient
    private var ixWebsocketClient: IxWebsocketClient
    
    @State private var presentingSafariView = false
    @State private var urlToPresentInSafariView: URL?
    
    init() {
        self.modelContainer = ModelContainerProvider.shared
        
        let authHelper = AuthenticationHelper()
        self._authenticationHelper = StateObject(wrappedValue: authHelper)
        
        self.ixApiClient = IxApiClient { newAuthStatus in
            Task { @MainActor in
                authHelper.setBackendAuthStatus(newAuthStatus)
            }
        }
        
        let websocketEventHandler = IxWebsocketEventHandler(ixApiClient: ixApiClient, modelContext: modelContainer.mainContext)
        let websocketClient = IxWebsocketClient(ixWebsocketEventHandler: websocketEventHandler)
        self.ixWebsocketClient = websocketClient
    }
    
    func onBackendAuthStatusChange(_ authStatus: AuthStatus) {
        switch authStatus {
        case .loading:
            log.debug("api client authentication loading")
        case .unauthenticated:
            log.debug("api client unauthenticated")
            
            Task { @MainActor in
                self.user = nil
                
                do {
                    try modelContainer.mainContext.transaction {
                        try modelContainer.mainContext.delete(model: IxList.self)
                        try modelContainer.mainContext.delete(model: IxListCategory.self)
                        try modelContainer.mainContext.delete(model: IxListItem.self)
                        try modelContainer.mainContext.delete(model: IxTask.self)
                    }
                } catch {
                    log.error("Failed to clear database data: \(error)")
                }
            }
            
            
            Task.detached {
                async let disconnectResult: () = ixWebsocketClient.disconnect()
                async let clearRegisterResult: () = SyncRegister.shared.clear()
                async let revenueCatResult: () = RevenueCatHelper.logout()
                
                _ = await (disconnectResult, clearRegisterResult, revenueCatResult)
            }
        case let .authenticated(user: networkUser):
            log.debug("network client authenticated - id: \(networkUser.id) - email: \(networkUser.email)")
            
            Task { @MainActor in
                self.user = networkUser
            }
            
            Task.detached {
                await SyncRegister.shared.clear()
//                await ixWebsocketClient.connectAndHandleMessages()
            }
            
            Task.detached {
                async let firebaseTask: () = registerFirebaseToken(ixApiClient: ixApiClient)
                async let revenueCatTask: () = RevenueCatHelper.login(userId: networkUser.id)
                
                await (_, _) = (firebaseTask, revenueCatTask)
            }
        }
    }
    
    func onLocalAuthStatusChange(_ authStatus: AuthStatus) {
        switch authStatus {
        case .loading:
            log.debug("loading user from AppStorage")
        case .unauthenticated:
            log.debug("user not locally authenticated, AppStorage user is nil")
            authNavigationManager.clear()
            errorService.clear()
        case .authenticated(user: let user):
            log.debug("received user from AppStorage - id: \(user.id) - email: \(user.email)")
            errorService.clear()
            authNavigationManager.clear()
        }
    }
    
    private func registerFirebaseToken(ixApiClient: IxApiClient) async {
        do {
            let firebaseMessagingToken = try await Messaging.messaging().token()
            try await ixApiClient.sendNotificationRegistrationToken(token: firebaseMessagingToken)
        } catch {
            log.error("Failed sending firebase messaging token to server: \(error)")
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            MainView(authStatus: authenticationHelper.localAuthStatus)
                .onChange(of: authenticationHelper.backendAuthStatus, initial: true) { _, newBackendAuthStatus in
                    onBackendAuthStatusChange(newBackendAuthStatus)
                }
                .onChange(of: authenticationHelper.localAuthStatus, initial: true) { _, newLocalAuthStatus in
                    onLocalAuthStatusChange(newLocalAuthStatus)
                }
                .onChange(of: user, initial: true) { _, newLocalUser in
                    if let newLocalUser = newLocalUser {
                        authenticationHelper.setLocalAuthStatus(.authenticated(user: newLocalUser))
                    } else {
                        authenticationHelper.setLocalAuthStatus(.unauthenticated)
                    }
                }
                .environmentObject(authNavigationManager)
                .environmentObject(navigationManager)
                .environmentObject(errorService)
                .environment(\.ixApiClient, ixApiClient)
                .modelContainer(modelContainer)
                .defaultAppStorage(UserDefaults(suiteName: IxIdentifiers.APP_GROUP)!)
                .alertPresentationWindow(service: errorService)
                .onOpenURL { url in
                    if GIDSignIn.sharedInstance.handle(url) {
                        return
                    }
                    
                    UniversalLinksHelper.handleUniversalLink(url, navigationManager: navigationManager)
                }
                .environment(\.openURL, OpenURLAction { url in
                    self.urlToPresentInSafariView = url
                    self.presentingSafariView = true
                    return .handled
                })
                .sheet(isPresented: $presentingSafariView, onDismiss: { self.urlToPresentInSafariView = nil }) { [urlToPresentInSafariView] in
                    if let url = urlToPresentInSafariView {
                        SafariView(url: url)
                    }
                }
        }
    }
}
