//
//  ProSettingsView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/03/25.
//

import RevenueCat
import SwiftUI

struct ProSettingsView: View {
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.openURL) var openURL

    @State private var manageSubscriptionLoading: Bool = false

    private func manageSubscriptions() {
        manageSubscriptionLoading = true

        Purchases.shared.getCustomerInfo { customer, error in
            manageSubscriptionLoading = false
            if let error = error {
                errorService.insert(.localizedError(title: "Couldn't open subscriptions page", error: error))
                return
            }

            if let customer = customer {
                if let url = customer.managementURL {
                    openURL(url)
                }
            }
        }
    }

    var body: some View {
        List {
            currentlySubscribedCardView
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            Section {
                Button {
                    manageSubscriptions()
                } label: {
                    HStack {
                        if manageSubscriptionLoading {
                            ProgressView()
                                .controlSize(.regular)
                        }

                        Text("Manage subscription")
                    }
                }.disabled(manageSubscriptionLoading)
            }
        }
        .navigationTitle("Pro")
        .navigationBarTitleDisplayMode(.inline)
    }

    var currentlySubscribedCardView: some View {
        ZStack {
            HStack {
                HStack(spacing: 24) {
                    Image(systemName: "bolt.circle.fill")
                        .scaleEffect(1.75)
                        .opacity(0.8)

                    VStack(alignment: .leading) {
                        Text("Pro enabled")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Thank you for supporting the app :)")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background {
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            Color(red: 15 / 255, green: 40 / 255, blue: 25 / 255), // Darker green
                            Color(red: 25 / 255, green: 65 / 255, blue: 45 / 255), // Lighter green
                        ]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }.foregroundStyle(.white)
    }
}

#Preview {
    NavigationView {
        ProSettingsView()
    }
}
