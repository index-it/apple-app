//
//  FaviconImage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/01/26.
//

import SwiftUI

struct FaviconImage<Content: View, Placeholder: View>: View {
    let link: String
    let scale: CGFloat
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    private var faviconURL: URL? {
        guard let url = URL(string: link),
              let host = url.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
    }

    init(
        link: String,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.link = link
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let faviconURL = faviconURL {
                CachedAsyncImage(url: faviconURL, scale: scale) { image in
                    content(image)
                } placeholder: {
                    placeholder()
                }
            } else {
                placeholder()
            }
        }
    }
}
