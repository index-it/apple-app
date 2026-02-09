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
    @Environment(IxNavigator.self) var navigator

    let authStatus: AuthStatus

    var body: some View {
        @Bindable var navigator = navigator

        NavigationStack(path: $navigator.path) {
            Group {
                switch authStatus {
                case .loading:
                    SplashScreen()
                case .unauthenticated:
                    SocialLoginScreen()
                case .authenticated:
                    HomeScreen()
                }
            }.navigationDestination(for: IxNavRoute.self) { destination in
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
