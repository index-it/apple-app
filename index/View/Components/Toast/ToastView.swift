//
//  ToastView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 08/01/26.
//

import SwiftUI

struct ToastView: View {
    let info: ToastInfo

    init(info: ToastInfo) {
        self.info = info
    }

    init(message: String, systemImage: String?, tint: Color?, onTap: @escaping () -> Void) {
        info = ToastInfo(message: message, systemImage: systemImage, tint: tint, onTap: onTap)
    }

    var body: some View {
        HStack {
            if let systemImage = info.systemImage {
                Image(systemName: systemImage)
                    .foregroundColor(info.tint)
            }

            Text(info.message)
                .font(.callout)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            .background
                .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
                .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
            in: .capsule
        )
        .contentShape(.capsule)
        .onTapGesture {
            if let onTap = info.onTap {
                onTap()
            }
        }
    }
}

#Preview {
    ToastView(message: "Confirmation msg", systemImage: "checkmark", tint: .green) {}
}
