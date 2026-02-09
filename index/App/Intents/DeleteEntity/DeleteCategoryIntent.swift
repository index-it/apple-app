//
//  DeleteCategoryIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct DeleteCategoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Category"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Delete\(\.$category).")
    }

    @Parameter(title: "Category", description: "The category to delete")
    var category: IxListCategoryEntity

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        
        let delete = Option(title: "Delete", style: .destructive)
        
        let resultChoice = try await requestChoice(
            between: [.cancel, delete],
            dialog: "Are you sure you want to delete \(category.name)?"
        )
        
        switch resultChoice {
        case delete:
            let categoryId = category.id
            try? await ixApiClient.deleteListCategory(listId: category.listId, categoryId: categoryId)
            try? modelContainer.mainContext.delete(model: IxListCategory.self, where: #Predicate { $0.id == categoryId })
            try? await IxSystemIntegration.handleEntityDeletion(categoryId, of: IxListCategoryEntity.self)
            
            return .result(
                dialog: "\(category.name) deleted."
            )
        default:
            return .result(dialog: "Nothing was deleted")
        }
    }
}
