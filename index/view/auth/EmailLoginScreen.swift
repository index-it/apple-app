//
//  EmailLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI

struct EmailLoginScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var ixApiClient: IxApiClient
    
    @State private var email: String = ""
    @FocusState private var isEmailFocused: Bool
    @State private var loading: Bool = false
    
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".") && email.count >= 5
    }
    
    func getWelcomeActionAndNavigateToPasswordScreen() async {
        do {
            loading = true
            let welcomeAction = try await ixApiClient.welcomeAction(email: email)
            loading = false
            
            switch welcomeAction {
            case .LOGIN:
                navigationManager.push(navigationRoute: .PasswordLogin(email: email))
            case .REGISTER:
                navigationManager.push(navigationRoute: .PasswordRegister(email: email))
            }
        } catch {
            loading = false
            print("error: \(error)")
            // TODO: global error handling
        }
    }
    
    var body: some View {
        VStack {
            TextField("Insert your email", text: $email)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .focused($isEmailFocused)
                .onSubmit {
                    if (isEmailValid) {
                        Task {
                            await getWelcomeActionAndNavigateToPasswordScreen()
                        }
                    }
                }
           
            Button {
                Task {
                    await getWelcomeActionAndNavigateToPasswordScreen()
                }
            } label: {
                HStack {
                    if loading {
                        ProgressView()
                    }
                    
                    Text("Continue")
                }
            }.padding()
                .buttonStyle(.borderedProminent).disabled(!isEmailValid)
        }.padding()
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                isEmailFocused = true
            }
    }
}

#Preview {
    EmailLoginScreen()
}
