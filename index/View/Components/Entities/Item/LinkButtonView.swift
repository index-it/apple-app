//
//  LinkButtonView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import SwiftUI

struct LinkButtonView: View {
    let link: String
    let url: URL?
    let onOpenLink: () -> Void

    var body: some View {
        Button {
            onOpenLink()
        } label: {
            HStack(spacing: 6) {
                FaviconImage(link: link) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.buttonBorder)
                        .frame(width: 24, height: 24)
                } placeholder: {
                    Image(systemName: "globe")
                        .frame(width: 16, height: 24)
                }

                Text(url?.host.flatMap { $0.hasPrefix("www.") ? String($0.dropFirst(4)) : $0 } ?? link)
                    .font(.footnote)
            }
        }
        .foregroundStyle(Color.systemLabel)
        .buttonBorderShape(.roundedRectangle)
        .controlSize(.small)
        .buttonStyle(.bordered)
        .contextMenu {
            Button("Copy", systemImage: "document.on.document") {
                UIPasteboard.general.url = url
            }

            if let url = url {
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        } preview: {
            if let url = url {
                SafariView(url: url)
            }
        }
    }
}
