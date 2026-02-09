//
//  CreateListIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit



@available(iOS 26.0, *)
struct CreateListIntent: AppIntent {
    static let title: LocalizedStringResource = "Create list"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create a list named \(\.$name), optionally with \(\.$icon) emoji and \(\.$color) color and add \(\.$items) items to the list.")
    }

    @Parameter(title: "Name")
    var name: String
    
    @Parameter(title: "Icon", description: "The emoji to use as the list icon")
    var icon: String?
    
    @Parameter(title: "Color", description: "The color for the list")
    var color: IxColorEnum?
    
    @Parameter(title: "Items", description: "Items to add to this list")
    var items: [String]?

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListEntity> & ProvidesDialog & ShowsSnippetView {
        let list = try await ixApiClient.createList(
            name: name,
            icon: icon?.emoji ?? EmojiHelper.randomEmoji(),
            color: color?.color.hexString ?? ColorHelper.randomIxColor().hexString,
            archived: false,
            is_public: false
        )

        let modelContext = modelContainer.mainContext
        
        try modelContext.transaction {
            modelContext.insert(list)
        }
        
        let listEntity = IxListEntity(list: list)
        try? await IxSystemIntegration.handleNewEntity(listEntity)
        
        if let items = items, !items.isEmpty {
            var newItems: [IxListItem] = []
            
            for itemName in items {
                let newItem = try await ixApiClient.createListItem(
                    listId: list.id,
                    categoryId: nil,
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
            full: "Created list \(list.icon) \(list.name).",
            supporting: "Here's the created list."
        )
        
        return .result(
            value: listEntity,
            dialog: dialog
        )
    }
}
