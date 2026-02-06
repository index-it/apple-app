//
//  CreateCategoryIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct CreateCategoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Create a new list category"

    static var parameterSummary: some ParameterSummary {
        Summary("Create a category in \(\.$list) with \(\.$name)")
    }

    @Parameter var list: IxListEntity
    @Parameter(title: "Name")
    var name: String

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListCategoryEntity> {
        let category = try await ixApiClient.createCategory(listId: list.id, name: name, color: nil)

        let modelContext = modelContainer.mainContext
        
        try modelContext.transaction {
            modelContext.insert(category)
        }

        return .result(value: IxListCategoryEntity(category: category))
    }
}
