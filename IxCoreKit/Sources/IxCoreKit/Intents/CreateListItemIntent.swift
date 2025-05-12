//
//  CreateListItemIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import AppIntents


@available(iOS 18.0, *)
public struct CreateListItemIntent: AppIntent {
    public static let title: LocalizedStringResource = "Create List Item"
    public static let description: IntentDescription = "Create a new list item"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: "https://web.index-it.app/create-item") else {
            throw URLError(.badURL)
        }
        
        return .result(opensIntent: OpenURLIntent(url))
    }
    
    public static let openAppWhenRun: Bool = true
}
