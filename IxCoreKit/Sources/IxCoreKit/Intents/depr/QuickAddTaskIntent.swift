//
//  QuickAddTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import AppIntents

@available(iOS 18.0, *)
public struct QuickAddTaskIntent: DeprecatedAppIntent {
    public static let title: LocalizedStringResource = "Create Task"
    public static let description: IntentDescription = "Create a new task"

    public init() {}

    public func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: IxUniversalLinks.quickAdd(.task)) else {
            throw URLError(.badURL)
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}
