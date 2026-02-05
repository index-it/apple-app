//
//  OpenListCategoryIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/02/26.
//

// TODO: navigation for single category not implemented yet

//import AppIntents
//
//@available(iOS 26.0, *)
//struct OpenListCategoryIntent: OpenIntent {
//    static let title: LocalizedStringResource = "Open Category"
//
//    @Parameter(title: "Category", requestValueDialog: "Which category?")
//    var target: IxListCategoryEntity
//
//    func perform() async throws -> some IntentResult {
//        guard let url = URL(string: IxUniversalLinks.category(listId: target.listId, target.id)) else {
//            throw URLError(.badURL)
//        }
//        return .result(opensIntent: OpenURLIntent(url))
//    }
//}
