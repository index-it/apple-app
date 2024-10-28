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
    
    var email: String
    
    @State private var password: String = ""
    @State private var isPasswordSecure: Bool = true
    @FocusState private var isPasswordFocused: Bool
    @State private var loading = false
    
    func login() async {
        do {
            loading = true
            try await ixApiClient.login(email: email, password: password)
            loading = false
            // app will automatically navigate to the authenticated screens
            // thanks to the auth status stored in the IxApiClient
        } catch IxApiClientError.Unauthenticated {
            loading = false
            // TODO
        } catch IxApiClientError.EmailNotVerified {
            loading = false
            authNavigationManager.push(navigationRoute: .EmailVerification(email: email, password: password))
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
                    Image(systemName: isPasswordSecure ? "eye" : "eye.slash")
                }.frame(maxWidth: .infinity, alignment: .trailing).padding()
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
            .onAppear {
                isPasswordFocused = true
            }
    }
}

#Preview {
    PasswordLoginScreen(email: "test@gmail.com")
        .environmentObject(AuthNavigationManager())
        .environmentObject(IxApiClient())
}
