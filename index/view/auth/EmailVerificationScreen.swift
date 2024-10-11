//
//  EmailVerificationScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import SwiftUI

struct EmailVerificationScreen: View {
    @EnvironmentObject var ixApiClient: IxApiClient
    
    var email: String
    var password: String
    
    func isEmailVerified() async {
        do {
            let verified = try await ixApiClient.isEmailVerified(email: email, password: password)
            
            if (verified) {
                try await ixApiClient.login(email: email, password: password)
                // this will auto navigate to home on successful login
            }
        } catch IxApiClientError.Unauthenticated {
            // TODO
        } catch {
            // TODO
        }
    }
    
    func sendVerificationEmail() async {
        do {
            let sent = try await ixApiClient.sendVerificationEmail(email: email, password: password)
            
            if (!sent) {
                try await ixApiClient.login(email: email, password: password)
                // this will auto navigate to home on successful login
            }
        } catch IxApiClientError.Unauthenticated {
            // TODO
        } catch IxApiClientError.TooManyRequests {
            // TODO
        } catch {
            
        }
    }
    
    var body: some View {
        VStack {
            Button("I verified it!") {
                Task {
                    await isEmailVerified()
                }
            }.buttonStyle(.borderedProminent)
            
            Button("Send another") {
                Task {
                    await sendVerificationEmail()
                }
            }
        }.padding()
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    EmailVerificationScreen(email: "test@gmail.com", password: "password")
}
