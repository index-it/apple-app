//
//  ShowToastAction.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 08/01/26.
//

import SwiftUI

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
