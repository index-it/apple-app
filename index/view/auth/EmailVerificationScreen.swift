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
    
    @State private var sendLoading = false
    @State private var verificationLoading = false
    
    func isEmailVerified() async {
        do {
            verificationLoading = true
            let verified = try await ixApiClient.isEmailVerified(email: email, password: password)
            verificationLoading = false
            
            if (verified) {
                try await ixApiClient.login(email: email, password: password)
                // this will auto navigate to home on successful login
            }
        } catch IxApiClientError.Unauthenticated {
            verificationLoading = true
            // TODO
        } catch {
            verificationLoading = true
            // TODO
        }
    }
    
    func sendVerificationEmail() async {
        do {
            sendLoading = true
            let sent = try await ixApiClient.sendVerificationEmail(email: email, password: password)
            sendLoading = false
            
            if (!sent) {
                try await ixApiClient.login(email: email, password: password)
                // this will auto navigate to home on successful login
            }
        } catch IxApiClientError.Unauthenticated {
            sendLoading = false
            // TODO
        } catch IxApiClientError.TooManyRequests {
            sendLoading = false
            // TODO
        } catch {
            sendLoading = false

        }
    }
    
    var body: some View {
        VStack {
            Text("A verification email has been sent to \(email).\nPlease follow the instructions in the email to verify your account.")
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            
            Button {
                Task {
                    await sendVerificationEmail()
                }
            } label: {
                HStack {
                    if sendLoading {
                        ProgressView()
                            .controlSize(.regular)
                    }
                    
                    Text("Resend")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(sendLoading)
                
            Button {
                Task {
                    await isEmailVerified()
                }
            } label: {
                HStack {
                    if verificationLoading {
                        ProgressView()
                            .controlSize(.regular)
                    }
                    
                    Text("I verified it!")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)
                .controlSize(.large)
            
        }.frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("Verify your email")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Open emails") {
                        if let emailUrl = URL(string: "message:") {
                            if UIApplication.shared.canOpenURL(emailUrl) {
                                UIApplication.shared.open(emailUrl)
                            }
                        }
                    }
                }
            }
            .onAppear {
                
            }
    }
}

#Preview {
    EmailVerificationScreen(email: "test@gmail.com", password: "password")
}
