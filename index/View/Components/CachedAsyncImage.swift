//
//  CachedAsyncImage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/01/26.
//

import IxCoreKit
import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL
    let scale: CGFloat
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var cachedImage: UIImage?

    init(
        url: URL,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let cachedImage {
                content(Image(uiImage: cachedImage))
            } else {
                AsyncImage(url: url, scale: scale) { phase -> AnyView in
                    switch phase {
                    case let .success(image):
                        Task {
                            await saveToCache(from: url)
                        }
                        return AnyView(content(image))
                    case .failure:
                        return AnyView(placeholder())
                    case .empty:
                        return AnyView(placeholder())
                    @unknown default:
                        return AnyView(placeholder())
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadFromCache()
            }
        }
    }

    private func loadFromCache() async {
        if let cached = await ImageCacheHelper.shared.get(for: url.absoluteString) {
            await MainActor.run {
                cachedImage = cached
            }
        }
    }

    private func saveToCache(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                await ImageCacheHelper.shared.set(uiImage, for: url.absoluteString)

                await MainActor.run {
                    if cachedImage == nil {
                        cachedImage = uiImage
                    }
                }
            }
        } catch {
            print("Image caching failed: \(error)")
        }
    }
}
