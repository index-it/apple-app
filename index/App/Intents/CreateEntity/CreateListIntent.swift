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
    static let title: LocalizedStringResource = "Create a new list"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create a list with \(\.$name)")
    }

    @Parameter(title: "Name")
    var name: String

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxListEntity> {
        let list = try await ixApiClient.createList(
            name: name,
            icon: EmojiHelper.randomEmoji(),
            color: ColorHelper.randomIxColor().hexString,
            archived: false,
            is_public: false
        )

        let modelContext = modelContainer.mainContext
        
        try modelContext.transaction {
            modelContext.insert(list)
        }

        return .result(value: IxListEntity(list: list))
    }
}
