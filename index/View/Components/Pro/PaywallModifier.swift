//
//  PaywallModifier.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/03/25.
//

import SwiftUI

struct PaywallModifier: ViewModifier {
    @ObservedObject var service: PaywallStateService

    func body(content: Content) -> some View {
        content
            .environment(\.showPaywall, ShowPaywallAction {
                service.isShown = true
            })
            .fullScreenCover(isPresented: $service.isShown) {
                PaywallView {
                    service.isShown = false
                }
            }
    }
}

extension View {
    func paywallCover(service: PaywallStateService) -> some View {
        modifier(PaywallModifier(service: service))
    }
}
