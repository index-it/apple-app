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

    init(message: String, systemImage: String?, onTap: @escaping () -> Void) {
        info = ToastInfo(message: message, systemImage: systemImage, onTap: onTap)
    }

    var body: some View {
        HStack {
            if let systemImage = info.systemImage {
                Image(systemName: systemImage)
            }

            Text(info.message)
                .font(.callout)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .onTapGesture {
            if let onTap = info.onTap {
                onTap()
            }
        }
    }
}

#Preview {
    ToastView(message: "Confirmation msg", systemImage: "checkmark") {}
}
