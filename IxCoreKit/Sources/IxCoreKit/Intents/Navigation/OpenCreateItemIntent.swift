//
//  OpenCreateItemIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents

@available(iOS 18.0, *)
public struct OpenCreateItemIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open item creation"
    public static let description: IntentDescription = "Open the app and navigate to the item creation screen"

    public init() {}

    public func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: IxUniversalLinks.quickAdd(.item)) else {
            throw URLError(.badURL)
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}
