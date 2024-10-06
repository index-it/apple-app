//
//  PasswordLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI

struct PasswordLoginScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var ixApiClient: IxApiClient
    
    var email: String
    
    @State private var password: String = ""
    @State private var loading = false
    
    func login() async {
        do {
            try await ixApiClient.login(email: email, password: password)
            // app will automatically navigate to the authenticated screens
            // thanks to the auth status stored in the IxApiClient
        } catch IxApiClientError.Unauthenticated {
            // TODO
        } catch IxApiClientError.EmailNotVerified {
            navigationManager.push(navigationRoute: .EmailVerification(email: email, password: password))
        } catch {
            // TODO
        }
    }
    
    var body: some View {
        VStack {
            SecureField("Password", text: $password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.password)
            
            
            Button {
                Task {
                    await login()
                }
            } label: {
                HStack {
                    if loading {
                        ProgressView()
                    }
                    
                    Text("Login")
                }
            }.padding()
                .buttonStyle(.borderedProminent)
        }.padding()
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    PasswordLoginScreen(email: "test@gmail.com")
        .environmentObject(NavigationManager())
        .environmentObject(IxApiClient())
}
