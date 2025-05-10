//
//  ProView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var errorService: ErrorStateService
    
    private struct ProFeatureShowcase {
        let icon: String
        let title: String
    }
    
    static private var features: [ProFeatureShowcase] = [
        .init(icon: "infinity", title: "Unlimited lists"),
        .init(icon: "person.3.fill", title: "Public lists"),
        .init(icon: "bell.fill", title: "Unlimited task reminders"),
        .init(icon: "hammer.fill", title: "Support the development")
    ]
    
    @State private var packages: [Package] = []
    @State private var selectedPackage: Package? = nil
    @State private var paymentLoading = false
    
    @State private var restorePurchasesLoading = false
    
    var onDismiss: () -> Void
    
    func restorePurchases() async {
        do {
            restorePurchasesLoading = true
            let _ = try await ixApiClient.restorePurchases()
            restorePurchasesLoading = false
        } catch IxApiClientError.NotFound {
            restorePurchasesLoading = false
            errorService.insert(.customMessage(title: "Not subscribed", message: "You are not subscribed to the Pro version."))
        } catch {
            restorePurchasesLoading = false
        }
    }
    
    func purchaseSelectedPackage() async {
        guard let package = selectedPackage else { return }
        
        do {
            paymentLoading = true
            let info = try await Purchases.shared.purchase(package: package)
            
            if !info.userCancelled {
                // we should receive a ws event, but in case we don't we manually refresh the user
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    Task {
                        do {
                            let _ = try await ixApiClient.me()
                        } catch {}
                    }
                }
            }
            
            paymentLoading = false
        } catch {
            paymentLoading = false
            errorService.insert(.localizedError(title: "Failed purchasing", error: error))
        }
    }
    
    var body: some View {
        paywallView
            .onAppear {
                Purchases.shared.getOfferings { offerings, error in
                    if let error = error {
                        errorService.insert(.localizedError(title: "Error fetching offers", error: error))
                        return
                    }
                    
                    guard let offerings = offerings else { return }
                    
                    if let availablePackages = offerings.current?.availablePackages {
                        packages = availablePackages
                        selectedPackage = packages.first
                    }
                }
            }
    }
    
    var paywallView: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("be intentional.\nget pro.")
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Features you will unlock:")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }.padding(.bottom, 6)
                
                    
                    Grid(verticalSpacing: 12) {
                        ForEach(Self.features, id: \.title) { feature in
                            GridRow {
                                Image(systemName: feature.icon)
                                
                                Text(feature.title)
                                    .gridColumnAlignment(.leading)
                                    .foregroundStyle(Color.primary.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 48)
                
                
                VStack {
                    packagesView
                    
                    Button {
                        Task {
                            await purchaseSelectedPackage()
                        }
                    } label: {
                        HStack {
                            if packages.isEmpty || paymentLoading {
                                ProgressView()
                                    .controlSize(.regular)
                            }
                            
                            Text(paymentLoading ? "Upgrading" : "Upgrade")
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding()
                        .disabled(packages.isEmpty || paymentLoading)
                    
                    Button {
                        Task {
                            await restorePurchases()
                        }
                    } label: {
                        HStack {
                            if restorePurchasesLoading {
                                ProgressView()
                                    .controlSize(.regular)
                            }
                            Text("Restore purchases")
                        }
                    }
                    
                }.frame(maxWidth: .infinity)
            }
            .meshGradientBackground()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                    }
                }
            }
        }.environment(\.colorScheme, .dark)
    }
    
    var packagesView: some View {
        VStack {
            ForEach(packages, id: \.identifier) { package in
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            let monthly = package.packageType == .monthly
                            
                            Text(monthly ? "Monthly" : "Yearly")
                                .font(.headline)
                            Text("\(package.localizedPriceString) per \(monthly ? "month" : "year")")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Toggle(isOn: Binding(
                            get: { selectedPackage?.identifier == package.identifier },
                            set: { isSelected in
                                if isSelected {
                                    selectedPackage = package
                                }
                            }
                        )) {
                            Text("Select \(package.identifier)")
                        }
                        .toggleStyle(iOSCheckboxToggleStyle())
                        .scaleEffect(1.2)
                    }.padding()
                }
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(UIColor.tertiarySystemBackground.toColor())
                        .if(selectedPackage?.identifier == package.identifier, transform: { view in
                            view
                                .stroke(Color.accentColor, lineWidth: 2)
                        })
                }
                .padding(.horizontal)
                .onTapGesture {
                    selectedPackage = package
                }
            }
        }
    }
}

#Preview {
    PaywallView() {}
}
