//
//  EditItemIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct EditItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Item"

    static var parameterSummary: some ParameterSummary {
        Summary("Edit \(\.$item).") {
            \.$name
            \.$link
            \.$note
            \.$completed
        }
    }

    @Parameter(title: "Item", description: "The item to edit")
    var item: IxListItemEntity

    @Parameter(title: "Name")
    var name: String?

    @Parameter(title: "Link", description: "A link to add to the item")
    var link: URL?

    @Parameter(title: "Note", description: "A note to add to the item")
    var note: String?

    @Parameter(title: "Completed", description: "Whether the item is completed or not")
    var completed: Bool?

    @Parameter(title: "List", description: "Move the item to this list")
    var list: IxListEntity?

    @Parameter(title: "Category", description: "The category for the item")
    var category: IxListCategoryEntity?

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListItemEntity> & ProvidesDialog & ShowsSnippetIntent {
        let modelContext = modelContainer.mainContext
        let itemId = item.id
        let originalListId = item.listId

        var updatedItem: IxListItem? = nil
        if let list = list, list.id != item.listId {
            let resItem = try (await ixApiClient.moveListItems(listId: item.listId, itemIds: [itemId], moveListId: list.id, moveCategoryId: category?.id)).first

            if let resItem {
                updatedItem = resItem
            }
        }

        if name != nil || link != nil || note != nil || (category != nil && list?.id == originalListId) {
            updatedItem = try await ixApiClient.updateListItem(
                listId: item.listId,
                itemId: item.id,
                name: name ?? item.name,
                categoryId: category?.id ?? item.categoryId,
                link: link?.absoluteString ?? item.linkString,
                note: note ?? item.note
            )
        }

        // this should never happen
        guard let updatedItem else { throw IxIntentError.unknown }

        try modelContext.transaction {
            modelContext.insert(updatedItem)
        }

        let itemEntity = IxListItemEntity(item: updatedItem)
        try? await IxSystemIntegration.handleNewEntity(itemEntity)

        // full: read by the system when it cannot display the view
        // supporting: read before displaying the view
        let dialog = IntentDialog(
            full: "Modified \(item.name).",
            supporting: "Here's the modified item."
        )

        return .result(
            value: itemEntity,
            dialog: dialog,
            snippetIntent: ItemSnippetIntent(item: itemEntity)
        )
    }
}
