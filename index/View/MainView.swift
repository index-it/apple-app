//
//  MainView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/09/24.
//

import IxCoreKit
import SwiftData
import SwiftUI

struct MainView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    let authStatus: AuthStatus

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            Group {
                switch authStatus {
                case .loading:
                    SplashScreen()
                case .unauthenticated:
                    SocialLoginScreen()
                case .authenticated:
                    HomeScreen()
                }
            }.navigationDestination(for: NavigationRoute.self) { destination in
                switch destination {
                case .archivedLists:
                    ListsGridScreen(archived: true)
                case let .listRoute(listId: listId):
                    ListScreen(listId: listId)
                case .settings:
                    SettingsView()
                case .accountSettings:
                    AccountSettingsView()
                case .proSettings:
                    ProSettingsView()
                case .about:
                    AboutView()
                }
            }
        }
    }
}
