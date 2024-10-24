//
//  SocialLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignInSwift
import GoogleSignIn

struct SocialLoginScreen: View {
    @EnvironmentObject private var authNavigationManager: AuthNavigationManager
    @State private var showingEmailSheet = false
    
    private func loginWithGoogle() {
        // TODO: https://paulallies.medium.com/google-sign-in-swiftui-2909e01ea4ed
    }
    
    private func loginWithApple() {
        // TODO: https://www.kodeco.com/4875322-sign-in-with-apple-using-swiftui
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text("be intentional.")
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            
            VStack {
                VStack {
                    Button {
                        loginWithApple()
                    } label: {
                        Label {
                            Text("Continue with Apple")
                        } icon: {
                            Image(systemName: "apple.logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 24)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        loginWithGoogle()
                    } label: {
                        Label {
                            Text("Continue with Google")
                        } icon: {
                            Image("google_logo", bundle: Bundle.main)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 24)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    
                    Button {
                        showingEmailSheet = true
                    } label: {
                        Label {
                            Text("Continue with email")
                        } icon: {
                            Image(systemName: "envelope")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 16)
                                .fontWeight(.regular)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                }.foregroundStyle(.primary)
                    .fontWeight(.semibold)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding()
                
                
                Text("By continuing you agree to our \(Text("[Terms of Service](https://index-it.app/terms)").fontWeight(.semibold)) and \(Text("[Privacy Policy](https://index-it.app/privacy)").fontWeight(.semibold))")
                    .tint(.primary)
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }.frame(maxHeight: .infinity, alignment: .bottom)
        }.meshGradientBackground()
            .sheet(isPresented: $showingEmailSheet) {
                NavigationStack(path: $authNavigationManager.path) {
                    EmailLoginScreen()
                        .navigationDestination(for: AuthNavigationRoute.self) { destination in
                            switch destination {
                            case let .PasswordLogin(email: email):
                                PasswordLoginScreen(email: email)
                            case let .PasswordRegister(email: email):
                                PasswordRegisterScreen(email: email)
                            case let .EmailVerification(email: email, password: password):
                                EmailVerificationScreen(email: email, password: password)
                            }
                        }
                }
                
            }
    }
}

#Preview {
    SocialLoginScreen()
}
