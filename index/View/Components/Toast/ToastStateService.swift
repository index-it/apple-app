import IxCoreKit
import OSLog
import SwiftUI

private let log = Logger(subsystem: IxSubsystems.APP, category: "ToastStateService")

/// if we ever want to support multiple toasts (stacked on top of each other)
/// this is a good one
/// https://github.com/MatHeartGaming/coolStuff_with_SwiftUI/blob/main/AnimatedToasts/AnimatedToasts
public final class ToastStateService: ObservableObject {
    @Published var info: ToastInfo?
    @Published var placement: ToastPlacement = .bottom

    private var dismissTask: Task<Void, Never>?

    @MainActor
    func show(_ info: ToastInfo, placement: ToastPlacement) async {
        dismissTask?.cancel()

        if self.info != nil {
            self.info = nil

            try? await Task.sleep(for: .milliseconds(200))
        }

        self.info = info
        self.placement = placement

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self.info = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        info = nil
    }
}
