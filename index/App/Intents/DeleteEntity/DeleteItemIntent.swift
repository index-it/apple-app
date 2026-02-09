//
//  DeleteItemIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct DeleteItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Item"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Delete\(\.$item).")
    }

    @Parameter(title: "Item", description: "The item to delete")
    var item: IxListItemEntity

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let itemId = item.id
        try? await ixApiClient.deleteListItem(listId: item.listId, itemId: item.id)
        try? modelContainer.mainContext.delete(model: IxListItem.self, where: #Predicate { item in item.id == itemId })
        try? await IxSystemIntegration.handleEntityDeletion(itemId, of: IxListItemEntity.self)
        
        return .result(
            dialog: "\(item.name) deleted."
        )
    }
}
