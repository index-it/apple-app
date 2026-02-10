//
//  CreateItemIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct CreateItemIntent: AppIntent, PredictableIntent {
    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$name, \.$list)) { name, list in
            DisplayRepresentation(
                title: "Add \(name) to \(list)",
                synonyms: ["Create item \(name) in \(list)"]
            )
        }
    }
    
    static let title: LocalizedStringResource = "Create item"

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) to \(\.$list).") {
            \.$link
            \.$note
            \.$category
        }
    }

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "Link", description: "A link to add to the item")
    var link: URL?

    @Parameter(title: "Note", description: "A note to add to the item")
    var note: String?

    @Parameter(title: "List", description: "The list to which the item is added")
    var list: IxListEntity

    @Parameter(title: "Category", description: "The category to which the item is added")
    var category: IxListCategoryEntity?

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListItemEntity> & ProvidesDialog & ShowsSnippetIntent {
        let item = try await ixApiClient.createListItem(
            listId: list.id,
            categoryId: category?.id,
            name: name,
            link: link?.absoluteString,
            note: note
        )

        let modelContext = modelContainer.mainContext

        try modelContext.transaction {
            modelContext.insert(item)
        }

        let entity = IxListItemEntity(item: item)
        try? await IxSystemIntegration.handleNewEntity(entity)

        // full: read by the system when it cannot display the view
        // supporting: read before displaying the view
        let dialog = IntentDialog(
            full: "Added \(item.name) to \(list.name).",
            supporting: "Here's the created item."
        )

        return .result(
            value: entity,
            dialog: dialog,
            snippetIntent: ItemSnippetIntent(item: entity)
        )
    }
}
