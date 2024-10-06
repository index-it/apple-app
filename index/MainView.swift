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
    
    var body: some View {
        switch ixApiClient.authenticationStatus {
        case .Loading:
            SplashScreen()
        case .Unauthenticated:
            NavigationStack(path: $navigationManager.path) {
                // convert this to the splash screen, and add routes for auth / unauth, and add listener on auth status to change the path
                SocialLoginScreen()
                    .navigationDestination(for: NavigationRoute.self) { destination in
                        switch destination {
                        case .SocialLogin:
                            SocialLoginScreen()
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
        case let .Authenticated(user):
            Button("Logout from \(user.email)") {
                Task {
                    try await ixApiClient.logout()
                }
            }
        }
    }
}

#Preview {
    MainView()
}
