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
                case .EmailLogin:
                    EmailLoginScreen()
                case let .PasswordLogin(email):
                    PasswordLoginScreen(email: email)
                case let .PasswordRegister(email):
                    PasswordRegisterScreen(email: email)
                case let .EmailVerification(email: email, password: password):
                    EmailVerificationScreen(email: email, password: password)
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
