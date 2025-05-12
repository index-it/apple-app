//
//  CreateTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import AppIntents

@available(iOS 18.0, *)
public struct CreateTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Create Task"
    public static let description: IntentDescription = "Create a new task"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & OpensIntent {
        // Construct the URL to open the app on the create task page
        guard let url = URL(string: "https://web.index-it.app/create-task") else {
            throw URLError(.badURL)
        }
        
        return .result(opensIntent: OpenURLIntent(url))
    }
    
    public static let openAppWhenRun: Bool = true
}
