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
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    
    @State private var socialLoginViewModel = SignInWithAppleController()
    
    @State private var showingEmailSheet = false
    
    private func loginWithGoogle() {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {return}

        let _ = GIDConfiguration.init(clientID: "367062845885-0f6o9fj6cbebggmkbbrmseagbln33m2c.apps.googleusercontent.com")
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { res, error in
                guard let token = res?.user.idToken else {
                    return
                }
                
                Task {
                    do {
                        try await ixApiClient.loginWithGoogle(idToken: token.tokenString)
                    } catch IxApiClientError.EmailNotVerified {
                        errorService.insert(.customMessage(title: "Google email not verified", message: "Your Google email is not verified, please verify the email of your Google account before using it to login."))
                    } catch {
                        errorService.insert(.customMessage(title: "Error", message: "Couldn't login via Google, please use another method or try again later"))
                    }
                }
            }
    }
    
    private func loginWithApple() {
        socialLoginViewModel.setup(ixApiClient: ixApiClient, errorService: errorService)
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = socialLoginViewModel
        controller.presentationContextProvider = socialLoginViewModel
        controller.performRequests()
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
                
                
                Text("By continuing you agree to our \(Text("[Terms of Service](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)").fontWeight(.semibold)) and \(Text("[Privacy Policy](https://index-it.app/privacy)").fontWeight(.semibold))")
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
                            case let .EmailVerification(email: email, password: password, verificationEmailSent: verificationEmailSent):
                                EmailVerificationScreen(email: email, password: password, verificationEmailSent: verificationEmailSent)
                            }
                        }
                }
            }
    }
}

/// Remember to call the `setup` function before using!
@Observable
class SignInWithAppleController: NSObject, ASAuthorizationControllerDelegate {
    private var ixApiClient: IxApiClient?
    private var errorService: ErrorStateService?
    
    func setup(ixApiClient: IxApiClient, errorService: ErrorStateService) {
        self.ixApiClient = ixApiClient
        self.errorService = errorService
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let ixApiClient, let errorService else {
            print("IxApiClient or ErrorStateService is not initialized, remember to call the setup() function before using this class")
            return
        }
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let token = appleIDCredential.identityToken,
           let idToken = String(data: token, encoding: .utf8){
            Task {
                do {
                    try await ixApiClient.loginWithApple(idToken: idToken)
                } catch IxApiClientError.EmailNotVerified {
                    errorService.insert(.customMessage(title: "Apple email not verified", message: "Your Apple email is not verified, please verify the email of your Apple account before using it to login."))
                } catch {
                    errorService.insert(.customMessage(title: "Error", message: "Couldn't login via Apple, please use another method or try again later"))
                }
            }
        } else {
            errorService.insert(.customMessage(title: "Error", message: "Couldn't login via Apple, please use another method or try again later"))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // can ignore
    }
}

extension SignInWithAppleController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Provide the window of your app (assuming a single-window app)
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first ?? UIWindow()
    }
}

#Preview {
    SocialLoginScreen()
}
