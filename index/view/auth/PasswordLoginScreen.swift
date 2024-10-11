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
            try await ixApiClient.login(email: email, password: password)
            // app will automatically navigate to the authenticated screens
            // thanks to the auth status stored in the IxApiClient
        } catch IxApiClientError.Unauthenticated {
            // TODO
        } catch IxApiClientError.EmailNotVerified {
            authNavigationManager.push(navigationRoute: .EmailVerification(email: email, password: password))
        } catch {
            // TODO
        }
    }
    
    var body: some View {
        VStack {
//            HStack {
//                
//                
//                TODO: Create text field modifier
//                Button {
//                    isPasswordSecure.toggle()
//                } label: {
//                    Image(systemName: isPasswordSecure ? "eye" : "eye.slash")
//                }
//            }
            
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
            .navigationTitle("Login with your password")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                isPasswordFocused = true
            }
            .toolbar {
              ToolbarItem(placement: .principal) { Color.clear }
            }
    }
}

#Preview {
    PasswordLoginScreen(email: "test@gmail.com")
        .environmentObject(NavigationManager())
        .environmentObject(IxApiClient())
}
