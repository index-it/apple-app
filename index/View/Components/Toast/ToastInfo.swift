import SwiftUI

struct ToastInfo: Equatable {
    var message: String
    var systemImage: String?
    var tint: Color?
    var onTap: (() -> Void)?

    static func == (lhs: ToastInfo, rhs: ToastInfo) -> Bool {
        return lhs.message == rhs.message && lhs.systemImage == rhs.systemImage
    }
}

enum ToastPlacement {
    case top
    case bottom
}
