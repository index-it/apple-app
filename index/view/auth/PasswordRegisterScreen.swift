//
//  PasswordRegisterScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI

struct PasswordRegisterScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var ixApiClient: IxApiClient
    
    var email: String
    
    @State private var password: String = ""
    @State private var passwordRepeat: String = ""
    
    @State private var isPasswordSecure: Bool = true
    @State private var isPasswordRepeatSecure: Bool = true
    
    @State private var loading = false
    private var passwordFieldsValid: Bool {
        password == passwordRepeat && (8...100).contains(password.count) && password.wholeMatch(of: /(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*$/) != nil
    }
    
    func register() async {
        do {
            let emailSent = try await ixApiClient.register(email: email, password: password)
            
            if (!emailSent) {
                Task {
                    try await ixApiClient.sendVerificationEmail(email: email, password: password)
                }
            }
            
            navigationManager.push(navigationRoute: .EmailVerification(email: email, password: password))
        } catch IxApiClientError.EmailOrPasswordFormatInvalid {
            // TODO
        } catch IxApiClientError.UnusableEmail {
            // TODO
        } catch {
            // TODO
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                if isPasswordSecure {
                    SecureField("Password", text: $password)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                        .textContentType(.password)
                } else {
                    TextField("Password", text: $password)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                        .textContentType(.password)
                }
                
                Button {
                    isPasswordSecure.toggle()
                } label: {
                    if isPasswordSecure {
                        Image(systemName: "eye")
                    } else {
                        Image(systemName: "eye.slash")
                    }
                }
            }
            
            HStack {
                if isPasswordRepeatSecure {
                    SecureField("Password repeat", text: $passwordRepeat)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                        .textContentType(.password)
                } else {
                    TextField("Password repeat", text: $passwordRepeat)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                        .textContentType(.password)
                }
                
//                Button {
//                    isPasswordRepeatSecure.toggle()
//                } label: {
//                    if isPasswordRepeatSecure {
//                        Image(systemName: "eye")
//                    } else {
//                        Image(systemName: "eye.slash")
//                    }
//                }
            }

            
            Button {
                Task {
                    await register()
                }
            } label: {
                HStack {
                    if loading {
                        ProgressView()
                    }
                    
                    Text("Register")
                }
            }.padding()
                .disabled(!passwordFieldsValid)
                .buttonStyle(.borderedProminent)
        }.padding()
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
