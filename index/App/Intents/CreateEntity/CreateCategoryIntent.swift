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
    static let title: LocalizedStringResource = "Create category"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add a \(\.$name) category to \(\.$list).") {
            \.$color
            \.$items
        }
    }

    @Parameter(title: "Name")
    var name: String
    
    @Parameter(title: "List", description: "The list to which the category is added")
    var list: IxListEntity
    
    @Parameter(title: "Color", description: "The color for the list")
    var color: IxColorEnum?
    
    @Parameter(title: "Items", description: "Items to add to the category")
    var items: [String]?

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListCategoryEntity> & ProvidesDialog & ShowsSnippetIntent {
        let category = try await ixApiClient.createCategory(
            listId: list.id,
            name: name,
            color: color?.color.hexString
        )

        let modelContext = modelContainer.mainContext
        
        try modelContext.transaction {
            modelContext.insert(category)
        }
        
        let entity = IxListCategoryEntity(category: category)
        try? await IxSystemIntegration.handleNewEntity(entity)
        
        var newItems: [IxListItem] = []
        if let items = items, !items.isEmpty {
            for itemName in items {
                let newItem = try await ixApiClient.createListItem(
                    listId: list.id,
                    categoryId: category.id,
                    name: itemName,
                    link: nil,
                    note: nil
                )
                newItems.append(newItem)
            }
           
            try modelContext.transaction {
                for newItem in newItems {
                    modelContext.insert(newItem)
                }
            }
            
            try? await IxSystemIntegration.handleNewEntities(newItems.map(IxListItemEntity.init))
        }

        // full: read by the system when it cannot display the view
        // supporting: read before displaying the view
        let dialog = IntentDialog(
            full: "Added category \(category.name) to \(list.name)\(newItems.isEmpty ? "" : " with \(newItems.count) items").",
            supporting: "I added a \(category.name) category to \(list.name)."
        )
        
        return .result(
            value: entity,
            dialog: dialog,
            snippetIntent: ListSnippetIntent(list: list)
        )
    }
}
