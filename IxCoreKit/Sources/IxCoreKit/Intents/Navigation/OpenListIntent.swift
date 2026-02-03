//
//  OpenListIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents

@available(iOS 18.0, *)
public struct OpenListIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open list"
    public static let description: IntentDescription = "Open the app and navigate to a list"

    public init() {}

    public func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: IxUniversalLinks.quickAdd(.task)) else {
            throw URLError(.badURL)
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}
