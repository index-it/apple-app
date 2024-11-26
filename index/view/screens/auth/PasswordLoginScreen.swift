//
//  PasswordLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI

struct PasswordLoginScreen: View {
    @EnvironmentObject var authNavigationManager: AuthNavigationManager
    @EnvironmentObject var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService

    var email: String
    
    @State private var password: String = ""
    @State private var isPasswordSecure: Bool = true
    @FocusState private var isPasswordFocused: Bool
    @State private var loading = false
    
    @State private var passwordResetEmailSending = false
    @State private var isPasswordResetAlertShown = false
    @State private var isPasswordResetSentAlertShown = false
    
    func login() async {
        do {
            loading = true
            try await ixApiClient.login(email: email, password: password)
            loading = false
            // app will automatically navigate to the authenticated screens
            // thanks to the auth status stored in the IxApiClient
        } catch IxApiClientError.Unauthenticated {
            loading = false
            errorService.insert(.customMessage(title: "Invalid credentials", message: "The password is incorrect, try again."))
        } catch IxApiClientError.EmailNotVerified {
            loading = false
            authNavigationManager.push(navigationRoute: .EmailVerification(email: email, password: password, verificationEmailSent: false))
        } catch {
            loading = false
            errorService.insert(.customMessage())
        }
    }
    
    func sendPasswordForgottenEmail() async {
        do {
            try await ixApiClient.passwordForgotten(email: email)
            isPasswordResetSentAlertShown = true
        } catch IxApiClientError.UserNotFound {
            errorService.insert(.customMessage(message: "User with email \(email) doesn't seem to exist. Are you sure you provided the correct email?"))
        } catch IxApiClientError.TooManyRequests {
            errorService.insert(.customMessage(title: "Too many requests", message: "You requested too many password resets, please check the spam folder of your inbox if you can't find the email we sent you previously."))
        } catch {
            
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                Group {
                    if isPasswordSecure {
                        SecureField("Insert your password", text: $password)
                    } else {
                        TextField("Insert your password", text: $password)
                    }
                }.autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .focused($isPasswordFocused)
                    .padding()
                    .background(isPasswordFocused ? .quaternary : .quinary)
                    .clipShape(.buttonBorder)
                    .onTapGesture {
                        isPasswordFocused = true
                    }
                    .onSubmit {
                        Task {
                            await login()
                        }
                    }
                
                Button {
                    isPasswordSecure.toggle()
                } label: {
                    Image(systemName: isPasswordSecure ? "eye.circle.fill" : "eye.slash.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, alignment: .trailing).padding()
            }
                
            
            
            Button {
                Task {
                    await login()
                }
            } label: {
                HStack {
                    if loading {
                        ProgressView()
                            .controlSize(.regular)
                    }
                    
                    Text("Login")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)
                .controlSize(.large)
            
        }.frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Login with password")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Password forgotten") {
                        isPasswordResetAlertShown = true
                    }
                }
            }
            .alert(
                "Password forgotten?",
                isPresented: $isPasswordResetAlertShown,
                actions: {
                    Button("Send") {
                        Task {
                            await sendPasswordForgottenEmail()
                            isPasswordResetAlertShown = false
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {
                        
                        isPasswordResetAlertShown = false
                    }
                },
                message: {
                    Text("We will send an email to \(email) with instructions on how to reset the password!")
                })
            .alert(
                "Instructions sent!",
                isPresented: $isPasswordResetSentAlertShown,
                actions: {
                    Button("Ok") {
                        isPasswordResetSentAlertShown = false
                    }
                },
                message: {
                    Text("An email with instructions on how to reset the password has been sent to \(email)")
                }
            )
            .onAppear {
                isPasswordFocused = true
            }
    }
}

#Preview {
        @Previewable @State var show = true
        VStack {
    
        }.sheet(isPresented: $show) {
            NavigationStack {
                PasswordLoginScreen(email: "test@gmail.com")
                    .environmentObject(AuthNavigationManager())
                    .environmentObject(IxApiClient())
            }
        }
    
    
}
