import SwiftUI

private struct ToastPresentationWindow: View {
    @ObservedObject var service: ToastStateService

    var body: some View {
        VStack {
            if service.placement == .bottom { Spacer() }

            if let info = service.info {
                ToastView(
                    message: info.message,
                    systemImage: info.systemImage
                ) {
                    service.dismiss()
                    info.onTap?()
                }
                .transition(
                    .move(edge: .top).combined(with: .opacity)
                )
                .padding(.top, 24)
                .contentShape(Rectangle())
            }

            if service.placement == .top { Spacer() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: service.info)
        .allowsHitTesting(true)
    }
}

private struct ToastPresentationWindowContext: ViewModifier {
    let service: ToastStateService

    @State private var toastWindow: UIWindow?

    func body(content: Content) -> some View {
        content
            .environment(\.showToast, ShowToastAction { info, placement in
                Task {
                    await service.show(info, placement: placement)
                }
            })
            .onAppear {
                guard toastWindow == nil else { return }
                let windowScene = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first { $0.windows.contains(where: \.isKeyWindow) }
                guard let windowScene else {
                    assertionFailure("Could not get UIWindowScene")
                    return
                }

                let window = PassThroughWindow(windowScene: windowScene)
                let controller = UIHostingController(rootView: ToastPresentationWindow(service: service))

                controller.view.backgroundColor = .clear
                window.rootViewController = controller
                window.windowLevel = .alert
                window.isHidden = false

                toastWindow = window
            }
    }
}

private final class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        // If we hit something that's not the root view, allow it
        if hitView != rootViewController?.view {
            return hitView
        }

        // Otherwise pass through
        return nil
    }
}

extension View {
    func toastPresentationWindow(service: ToastStateService) -> some View {
        modifier(ToastPresentationWindowContext(service: service))
    }
}
