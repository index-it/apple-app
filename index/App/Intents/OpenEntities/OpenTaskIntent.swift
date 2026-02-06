//
//  OpenTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/02/26.
//

// TODO: Navigation for single task not implemented yet

//import AppIntents
//
//@available(iOS 26.0, *)
//struct OpenTaskIntent: OpenIntent {
//    static let title: LocalizedStringResource = "Open Task"
//
//    @Parameter(title: "Task", requestValueDialog: "Which task?")
//    var target: IxTaskEntity
//
//    func perform() async throws -> some IntentResult {
//        guard let url = URL(string: IxUniversalLinks.tasks(target.id)) else {
//            throw URLError(.badURL)
//        }
//        return .result(opensIntent: OpenURLIntent(url))
//    }
//}
