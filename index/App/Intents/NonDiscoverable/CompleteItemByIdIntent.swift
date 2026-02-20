//
//  CompleteItemByIdIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct CompleteItemByIdIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete an item via its id"
    static var isDiscoverable: Bool = false
    static var supportedModes: IntentModes = .background

    @Parameter(title: "Item id")
    var itemId: String
    @Parameter(title: "List id")
    var listId: String

    init() {}

    init(itemId: String, listId: String) {
        self.itemId = itemId
        self.listId = listId
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListItemEntity> {
        // @Dependency doesn't work if the app has been in background for too long
        let ixApiClient = IxApiClient { _ in }
        let modelContext = ModelContainerProvider.shared.mainContext
        
        let item = try await ixApiClient.setListItemCompletion(listId: listId, itemId: itemId, completed: true)

        try modelContext.transaction {
            modelContext.insert(item)
        }

        let entity = IxListItemEntity(item: item)
        try? await IxSystemIntegration.handleNewEntity(entity)

        return .result(value: entity)
    }
}
