//
//  EmailVerificationScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import SwiftUI

struct EmailVerificationScreen: View {
    @EnvironmentObject var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService

    var email: String
    var password: String
    var verificationEmailSent: Bool
    
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
            verificationLoading = false
            errorService.insert(.customMessage(message: "Make sure you provided the correct email and password for your account and try again."))
        } catch {
            verificationLoading = false
            errorService.insert(.customMessage())
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
            errorService.insert(.customMessage(message: "Make sure you provided the correct email and password for your account and try again."))
        } catch IxApiClientError.TooManyRequests {
            sendLoading = false
            errorService.insert(.customMessage(title: "Too many requests", message: "You have requested too many verification emails, please check your spam folder for any previous email from us, consider checking your spam too!"))
        } catch {
            sendLoading = false
            errorService.insert(.customMessage())
        }
    }
    
    var body: some View {
        VStack {
            Text("A verification email has been sent to **\(email)**.\nPlease follow the instructions in the email to verify your account, consider checking your spam folder if you don't see the email!")
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
            .task {
                if (!verificationEmailSent) {
                    await sendVerificationEmail()
                }
                
                do {
                    while (true) {
                        try await Task.sleep(nanoseconds: 20_000_000_000)
                        await isEmailVerified()
                    }
                } catch {}
            }
    }
}

#Preview {
    EmailVerificationScreen(email: "test@gmail.com", password: "password", verificationEmailSent: true)
}
