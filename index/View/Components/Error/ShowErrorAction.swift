import SwiftUI

struct ShowErrorAction {
    let action: (ErrorAlert) -> Void

    func callAsFunction(
        _ alert: ErrorAlert
    ) {
        action(alert)
    }
}

extension EnvironmentValues {
    @Entry var showError = ShowErrorAction(action: { _ in })
}
