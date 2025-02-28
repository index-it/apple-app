//
//  PasswordRegisterScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI

struct PasswordRegisterScreen: View {
    @EnvironmentObject var authNavigationManager: AuthNavigationManager
    @EnvironmentObject var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService

    var email: String
    
    @State private var password: String = ""
    @State private var passwordRepeat: String = ""
    @FocusState private var isPasswordFocused: Bool

    @State private var isPasswordSecure: Bool = true
    @State private var isPasswordRepeatSecure: Bool = true
    @FocusState private var isPasswordRepeatFocused: Bool

    @State private var loading = false
    private var passwordValid: Bool {
        (8...100).contains(password.count) && password.wholeMatch(of: /(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*$/) != nil
    }
    private var passwordsMatch: Bool {
        password == passwordRepeat
    }
    
    func register() async {
        do {
            loading = true
            let emailSent = try await ixApiClient.register(email: email, password: password)
            loading = false
            
            if (!emailSent) {
                Task {
                    try await ixApiClient.sendVerificationEmail(email: email, password: password)
                }
            }
            
            authNavigationManager.push(navigationRoute: .EmailVerification(email: email, password: password, verificationEmailSent: true))
        } catch IxApiClientError.EmailOrPasswordFormatInvalid {
            loading = false
            errorService.insert(.customMessage(message: "Email or password formats are invalid, please make sure you provided a valid email and that your password contains at least an uppercase character, a lowercase one and a number. Additionally, the length must be between 8-100 characters!"))
        } catch {
            loading = false
            errorService.insert(.localizedError(title: nil, error: error))
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                Group {
                    if isPasswordSecure {
                        SecureField("Password", text: $password)
                    } else {
                        TextField("Password", text: $password)
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
                        isPasswordRepeatFocused = true
                    }

                
                Button {
                    isPasswordSecure.toggle()
                } label: {
                    Image(systemName: isPasswordSecure ? "eye.circle.fill" : "eye.slash.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }.frame(maxWidth: .infinity, alignment: .trailing).padding()
            }
            
            ZStack {
                Group {
                    if isPasswordRepeatSecure {
                        SecureField("Repeat the password", text: $passwordRepeat)
                    } else {
                        TextField("Repeat the password", text: $passwordRepeat)
                    }
                }.autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .focused($isPasswordRepeatFocused)
                    .padding()
                    .background(isPasswordRepeatFocused ? .quaternary : .quinary)
                    .clipShape(.buttonBorder)
                    .onTapGesture {
                        isPasswordRepeatFocused = true
                    }
                    .onSubmit {
                        Task {
                            if (passwordValid && passwordsMatch) {
                                await register()
                            }
                        }
                    }
                
                Button {
                    isPasswordRepeatSecure.toggle()
                } label: {
                    Image(systemName: isPasswordRepeatSecure ? "eye.circle.fill" : "eye.slash.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }.frame(maxWidth: .infinity, alignment: .trailing).padding()
            }
            
            
            if (passwordValid && !passwordsMatch && !passwordRepeat.isEmpty) {
                Text("The passwords don't match")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
            } else if (password.isEmpty || !passwordValid) {
                Text("Your password must contain an uppercase, a lowercase letter and a number")
                    .font(.footnote)
                    .foregroundStyle(passwordValid || password.isEmpty ? .gray : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
            }
            
            
            Button {
                Task {
                    if (passwordValid && passwordsMatch) {
                        await register()
                    }
                }
            } label: {
                HStack {
                    if loading {
                        ProgressView()
                            .controlSize(.regular)
                    }
                    
                    Text("Register")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)
                .disabled(!passwordValid || !passwordsMatch)
                .controlSize(.large)
            
        }.frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Create your password")
            .onAppear {
                isPasswordFocused = true
            }
    }
}

#Preview {
    PasswordRegisterScreen(email: "test@gmail.com")
        .environmentObject(AuthNavigationManager())
        .environmentObject(IxApiClient())
}
