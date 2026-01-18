//
//  ToastEnvironment.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 08/01/26.
//

import SwiftUI

struct ToastInfo {
    var message: String
    var systemImage: String?
    var onTap: (() -> Void)?
}

enum ToastPlacement {
    case top
    case bottom
}

struct ShowToastAction {
    let action: (ToastInfo, ToastPlacement) -> Void

    func callAsFunction(
        _ message: String,
        systemImage: String? = nil,
        placement: ToastPlacement = .bottom,
        _ tapAction: (() -> Void)? = nil
    ) {
        action(ToastInfo(message: message, systemImage: systemImage, onTap: tapAction), placement)
    }
}

extension EnvironmentValues {
    @Entry var showToast = ShowToastAction(action: { _, _ in })
}

struct ToastModifier: ViewModifier {
    @State private var info: ToastInfo?
    @State private var placement: ToastPlacement = .top
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .environment(\.showToast, ShowToastAction(action: { info, placement in
                Task { @MainActor in
                    // cancel any existing dismiss task
                    dismissTask?.cancel()

                    // if there's already a toast, dismiss it first
                    if self.info != nil {
                        withAnimation(.easeInOut) {
                            self.info = nil
                        }
                        try? await Task.sleep(for: .milliseconds(300))
                    }

                    // show new toast
                    withAnimation(.easeInOut) {
                        self.info = info
                        self.placement = placement
                    }

                    // schedule dismissal
                    dismissTask = Task {
                        try? await Task.sleep(for: .seconds(3))
                        guard !Task.isCancelled else { return }

                        withAnimation(.easeInOut) {
                            self.info = nil
                        }
                    }
                }
            }))
            .overlay(alignment: placement == .top ? .top : .bottom) {
                if let info {
                    ToastView(
                        message: info.message,
                        systemImage: info.systemImage
                    ) {
                        dismissTask?.cancel()
                        withAnimation(.easeInOut) {
                            self.info = nil
                        }

                        if let onTap = info.onTap {
                            onTap()
                        }
                    }
                    .transition(.move(edge: placement == .top ? .top : .bottom).combined(with: .opacity))
                    .padding(.top, 50)
                    .padding(.bottom, 70)
                }
            }
    }
}

extension View {
    func setupToast() -> some View {
        modifier(ToastModifier())
    }
}
