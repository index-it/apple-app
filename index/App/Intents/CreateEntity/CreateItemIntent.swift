//
//  CreateItemIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

//import AppIntents
//import SwiftData
//import IxCoreKit
//
//@available(iOS 26.0, *)
//struct CreateItemIntent: AppIntent {
//    static let title: LocalizedStringResource = "Create a new list item"
//    
//    static var parameterSummary: some ParameterSummary {
//        Summary("Create an item in \(\.$list) with \(\.$name) and optional \(\.$category), \(\.$link) and \(\.$note)")
//    }
//    
//    @Parameter var list: IxListEntity
//    @Parameter var category: IxListCategoryEntity?
//    @Parameter(title: "Name") var name: String
//    @Parameter(title: "Link", description: "A link stored in the item") var link: URL?
//    @Parameter(
//        title: "Note",
//        description: "A note for the item",
//        inputOptions: .init(multiline: true)
//    ) var note: String?
//    
//
//    @Dependency var modelContainer: ModelContainer
//    @Dependency var ixApiClient: IxApiClient
//
//    @MainActor
//    func perform() async throws -> some IntentResult & ReturnsValue<IxListItemEntity> {
//        let item = try await ixApiClient.createListItem(
//            listId: list.id,
//            categoryId: category?.id,
//            name: name,
//            link: link?.absoluteString,
//            note: note
//        )
//
//        let modelContext = modelContainer.mainContext
//        
//        try modelContext.transaction {
//            modelContext.insert(item)
//        }
//
//        return .result(value: IxListItemEntity(item: item))
//    }
//}
