//
//  OpenTasksIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents

@available(iOS 18.0, *)
public struct OpenTasksIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open tasks"
    public static let description: IntentDescription = "Open the app and navigate to the tasks screen"

    public init() {}

    public func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: IxUniversalLinks.tasks) else {
            throw URLError(.badURL)
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}
