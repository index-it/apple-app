//
//  ContentView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/09/24.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var ixApiClient: IxApiClient
    
    @Binding var authStatus: AuthStatus

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            Group {
                switch authStatus {
                case .Loading:
                    SplashScreen()
                case .Unauthenticated:
                    SocialLoginScreen()
                case .Authenticated:
                    HomeScreen()
                }
            }.navigationDestination(for: NavigationRoute.self) { destination in
                switch destination {
                case let .listRoute(listId: listId):
                    ListScreen(listId: listId)
                case .completedTasks:
                    CompletedTasksScreen()
                case .accountSettings:
                    AccountSettingsView()
                case .proSettings:
                    ProSettingsView()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var authStatus = AuthStatus.Loading
    
    MainView(authStatus: $authStatus)
        .environmentObject(NavigationManager())
        .environmentObject(IxApiClient())
}
