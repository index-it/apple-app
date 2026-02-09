//
//  DeleteListIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct DeleteListIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete List"

    static var parameterSummary: some ParameterSummary {
        Summary("Delete\(\.$list).")
    }

    @Parameter(title: "List", description: "The list to delete")
    var list: IxListEntity

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let archive = Option(title: "Archive", style: .default)
        let delete = Option(title: "Delete", style: .destructive)

        let resultChoice = try await requestChoice(
            between: [.cancel, archive, delete],
            dialog: "Do you want to archive or delete \(list.name)?"
        )

        let listId = list.id

        switch resultChoice {
        case archive:
            let newList = try await ixApiClient.editList(
                id: list.id,
                name: list.name,
                icon: list.icon,
                color: list.color,
                archived: true,
                is_public: list.isPublic
            )

            let modelContext = modelContainer.mainContext
            try modelContext.transaction {
                try modelContext.delete(model: IxList.self, where: #Predicate { $0.id == listId })
                modelContext.insert(newList)
            }

            try? await IxSystemIntegration.handleNewEntity(IxListEntity(list: newList))

            return .result(
                dialog: "\(list.name) archived."
            )
        case delete:
            try? await ixApiClient.deleteList(id: listId)
            try? modelContainer.mainContext.delete(model: IxList.self, where: #Predicate { $0.id == listId })
            try? await IxSystemIntegration.handleEntityDeletion(listId, of: IxListEntity.self)

            return .result(
                dialog: "\(list.name) deleted."
            )
        default:
            return .result(dialog: "Nothing was deleted")
        }
    }
}
