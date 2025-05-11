//
//  UniversalLinksHelper.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import Foundation
import IxCoreKit

struct UniversalLinksHelper {
    static func handleUniversalLink(_ url: URL, navigationManager: NavigationManager) {
        if url.host() != "web.index-it.app" {
            return
        }
        
        // Extract the path components, ignoring the domain for Universal Links
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard pathComponents.count >= 1 else { return }
        
        let section = pathComponents[0]
        
        switch section {
        case IxUniversalLinks.Sections.lists:
            if let listId = pathComponents[safe: 1] {
                navigationManager.push(.listRoute(listId: listId))
            } else {
                navigationManager.navigateToTab(.lists)
            }
        case IxUniversalLinks.Sections.tasks:
            navigationManager.navigateToTab(.tasks)
        case IxUniversalLinks.Sections.tasks:
            navigationManager.navigateToTab(.settings)
        default:
            return
        }
    }
}
