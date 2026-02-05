//
//  OpenListItemIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/02/26.
//

import AppIntents

// TODO: Navigation for single item not implemented yet
//
//@available(iOS 26.0, *)
//struct OpenListItemIntent: OpenIntent {
//    static let title: LocalizedStringResource = "Open Item"
//
//    @Parameter(title: "Item", requestValueDialog: "Which item?")
//    var target: IxListItemEntity
//
//    func perform() async throws -> some IntentResult {
//        guard let url = URL(string: IxUniversalLinks.item(listId: target.listId, target.id)) else {
//            throw URLError(.badURL)
//        }
//        return .result(opensIntent: OpenURLIntent(url))
//    }
//}
