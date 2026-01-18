import SwiftUI

struct ShowPaywallAction {
    let action: () -> Void

    func callAsFunction() {
        action()
    }
}

extension EnvironmentValues {
    @Entry var showPaywall = ShowPaywallAction(action: {})
}
