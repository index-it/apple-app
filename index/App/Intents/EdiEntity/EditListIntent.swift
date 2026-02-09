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
struct EditListIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit List"
    
    static var parameterSummary: some ParameterSummary {
        When(\.$items, .hasAnyValue) {
            Summary("Add \(\.$items) to \(\.$list)") {
                \.$name
                \.$icon
                \.$color
                \.$archive
                \.$items
            }
        } otherwise: {
            Summary("Edit \(\.$list).") {
                \.$name
                \.$icon
                \.$color
                \.$archive
                \.$items
            }
        }
    }
    
    @Parameter(title: "List", description: "The list to edit")
    var list: IxListEntity

    @Parameter(title: "Name")
    var name: String?
    
    @Parameter(title: "Icon", description: "The emoji to use as the list icon")
    var icon: String?
    
    @Parameter(title: "Color", description: "The color for the list")
    var color: IxColorEnum?
    
    @Parameter(title: "Archive", description: "Whether the list is archived or not")
    var archive: Bool?
    
    @Parameter(title: "Items", description: "Items to add to this list", default: [])
    var items: [String]
    
    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListEntity> & ProvidesDialog & ShowsSnippetIntent {
        let list = try await ixApiClient.editList(
            id: list.id,
            name: name ?? list.name,
            icon: icon?.emoji ?? list.icon,
            color: color?.color.hexString ?? list.color,
            archived: archive ?? list.archived,
            is_public: list.isPublic
        )

        let modelContext = modelContainer.mainContext
        
        let listId = list.id
        try modelContext.transaction {
            try modelContext.delete(model: IxList.self, where: #Predicate { list in list.id == listId })
            modelContext.insert(list)
        }
        
        let listEntity = IxListEntity(list: list)
        try? await IxSystemIntegration.handleNewEntity(listEntity)
        
        var newItems: [IxListItem] = []
        if !items.isEmpty {
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
        return .result(
            value: listEntity,
            dialog: IntentDialog(
                full: "List \(list.icon) \(list.name) modified\(newItems.isEmpty ? "" : " adding \(newItems.count) items").",
                supporting: "Here's the modified list."
            ),
            snippetIntent: ListSnippetIntent(list: listEntity)
        )
    }
}
