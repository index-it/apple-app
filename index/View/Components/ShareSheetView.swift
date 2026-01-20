//
//  ShareHelper.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 20/01/26.
//

import SwiftUI

struct ShareSheetView: UIViewControllerRepresentable {
    let item: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [item], applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
