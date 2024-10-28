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
            
            authNavigationManager.push(navigationRoute: .EmailVerification(email: email, password: password))
        } catch IxApiClientError.EmailOrPasswordFormatInvalid {
            loading = false
            // TODO
        } catch IxApiClientError.UnusableEmail {
            loading = false
            // TODO
        } catch {
            loading = false
            // TODO
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

                
                Button {
                    isPasswordSecure.toggle()
                } label: {
                    Image(systemName: isPasswordSecure ? "eye" : "eye.slash")
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
                    Image(systemName: isPasswordRepeatSecure ? "eye" : "eye.slash")
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
