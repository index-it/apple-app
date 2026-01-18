//
//  AlertPresentationWindow.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 17/11/24.
//

import SwiftUI

private struct AlertPresentationWindow: View {
    @ObservedObject var service: ErrorStateService

    var body: some View {
        Color.clear
            .alert(
                service.alerts.first?.title ?? "Error",
                isPresented: .init(
                    get: { service.alerts.first != nil },
                    set: { _ in service.remove(id: service.alerts.first?.id ?? "") }
                ),
                presenting: service.alerts.first,
                actions: { alert in
                    ForEach(alert.buttons, id: \.title) { button in
                        Button(button.title, role: button.isDestructive ? .destructive : nil, action: button.action)
                    }
                },
                message: { alert in Text(alert.message) }
            )
    }
}

private struct AlertPresentationWindowContext: ViewModifier {
    let service: ErrorStateService

    @State private var alertWindow: UIWindow?

    func body(content: Content) -> some View {
        content.onAppear {
            guard alertWindow == nil else { return }
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.windows.contains(where: \.isKeyWindow) }
            guard let windowScene else { return assertionFailure("Could not get a UIWindowScene") }

            let alertWindow = PassThroughWindow(windowScene: windowScene)
            let alertViewController = UIHostingController(rootView: AlertPresentationWindow(service: service))
            alertViewController.view.backgroundColor = .clear
            alertWindow.rootViewController = alertViewController
            alertWindow.isHidden = false
            alertWindow.windowLevel = .alert
            self.alertWindow = alertWindow
        }
    }
}

private final class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        // If the returned view is the `UIHostingController`'s view, ignore.
        return rootViewController?.view == hitView ? nil : hitView
    }
}

extension View {
    func alertPresentationWindow(service: ErrorStateService) -> some View {
        modifier(AlertPresentationWindowContext(service: service))
    }
}
