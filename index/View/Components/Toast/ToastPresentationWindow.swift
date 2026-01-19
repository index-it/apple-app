import SwiftUI
import WindowOverlay

private struct ToastPresentationWindow: View {
    @ObservedObject var service: ToastStateService

    var body: some View {
        VStack {
            if service.placement == .bottom { Spacer() }

            if let info = service.info {
                ToastView(
                    message: info.message,
                    systemImage: info.systemImage,
                    tint: info.tint
                ) {
                    service.dismiss()
                    info.onTap?()
                }
                .transition(.move(edge: service.placement == .top ? .top : .bottom).combined(with: .opacity))
                .padding(.top, 24)
                .padding(.bottom, 64)
                .contentShape(Rectangle())
            }

            if service.placement == .top { Spacer() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy, value: service.info)
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
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, toastWindow == nil {
                    let window = PassThroughWindow(windowScene: windowScene)
                    let rootController = UIHostingController(rootView: ToastPresentationWindow(service: service))
                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
                    rootController.view.backgroundColor = .clear
                    window.rootViewController = rootController
                    window.backgroundColor = .clear
                    window.isHidden = false
                    window.isUserInteractionEnabled = true

                    toastWindow = window
                }
            }
    }
}

extension View {
    func installToast(service: ToastStateService) -> some View {
        modifier(ToastPresentationWindowContext(service: service))
    }
}
