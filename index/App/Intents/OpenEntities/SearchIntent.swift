//
//  SearchIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/02/26.
//

import AppIntents
import Foundation
import IxCoreKit

@AppIntent(schema: .system.search)
struct SearchIntent: ShowInAppSearchResultsIntent {
    static var searchScopes: [StringSearchScope] = [.general]
    var criteria: StringSearchCriteria
    
    func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: IxUniversalLinks.search(criteria.term)) else {
            throw URLError(.badURL)
        }
        return .result(opensIntent: OpenURLIntent(url))
    }
}
