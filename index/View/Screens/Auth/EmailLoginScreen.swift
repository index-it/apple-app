//
//  EmailLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import IxCoreKit
import SwiftUI

struct EmailLoginScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject var authNavigationManager: AuthNavigationManager
    @EnvironmentObject private var errorService: ErrorStateService

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
                authNavigationManager.push(.passwordLogin(email: email))
            case .REGISTER:
                authNavigationManager.push(.passwordRegister(email: email))
            }
        } catch {
            loading = false
            errorService.insert(.localizedError(title: nil, error: error))
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
                .padding()
                .background(isEmailFocused ? .quaternary : .quinary)
                .clipShape(.buttonBorder)
                .onTapGesture {
                    isEmailFocused = true
                }
                .onSubmit {
                    if isEmailValid {
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
                            .controlSize(.regular)
                    }

                    Text("Continue")
                }.frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isEmailValid)

        }.frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .navigationTitle("What's your email?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isEmailFocused = true
            }
    }
}

#Preview {
    EmailLoginScreen()
}
