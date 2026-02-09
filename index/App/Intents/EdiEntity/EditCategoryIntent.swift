//
//  EditCategoryIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct EditCategoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Category"

    static var parameterSummary: some ParameterSummary {
        Summary("Edit \(\.$category).") {
            \.$name
            \.$color
            \.$items
        }
    }

    @Parameter(title: "Category", description: "The category to edit")
    var category: IxListCategoryEntity

    @Parameter(title: "Name")
    var name: String?

    @Parameter(title: "Color", description: "The color for the category")
    var color: IxColorEnum?

    @Parameter(title: "Items", description: "Items to add to this list", default: [])
    var items: [String]

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListCategoryEntity> & ProvidesDialog & ShowsSnippetIntent {
        let modelContext = modelContainer.mainContext
        let categoryId = category.id
        let listId = category.listId

        var listDescriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in list.id == listId }
        )
        listDescriptor.fetchLimit = 1
        guard let list = (try? modelContext.fetch(listDescriptor))?.first else {
            throw IxIntentError.listNotFound
        }

        let category = try await ixApiClient.updateListCategory(
            listId: listId,
            categoryId: categoryId,
            name: name ?? category.name,
            color: color?.color.hexString ?? category.color
        )

        try modelContext.transaction {
            try modelContext.delete(model: IxListCategory.self, where: #Predicate { $0.id == categoryId })
            modelContext.insert(category)
        }

        let categoryEntity = IxListCategoryEntity(category: category)
        try? await IxSystemIntegration.handleNewEntity(categoryEntity)

        // full: read by the system when it cannot display the view
        // supporting: read before displaying the view
        let dialog = IntentDialog(
            full: "Category \(category.name) modified.",
            supporting: "Here is the modified category in its list."
        )

        return .result(
            value: categoryEntity,
            dialog: dialog,
            snippetIntent: ListSnippetIntent(list: IxListEntity(list: list))
        )
    }
}
