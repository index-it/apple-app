//
//  UniversalLinksHelper.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import Foundation
import IxCoreKit
import os

private let log = Logger(subsystem: IxSubsystems.APP, category: "UniversalLinksHelper")

enum UniversalLinksHelper {
    static func handleUniversalLink(_ url: URL, navigator: IxNavigator) {
        if url.host() != "web.index-it.app" {
            navigator.navigateToTab(.lists)
            return
        }

        // Extract the path components, ignoring the domain for Universal Links
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard pathComponents.count >= 1 else { return }
        
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

        let section = pathComponents[0]

        switch section {
        case IxUniversalLinks.Sections.lists:
            navigator.navigateToTab(.lists)
            
            if let listId = pathComponents[safe: 1] {
                if let categoryId = urlComponents?
                    .queryItems?
                    .first(where: { $0.name == "categoryId" && $0.value != "nil" })?
                    .value {
                    
                    navigator.push(.listRoute(listId: listId))
                    navigator.categoryId = categoryId
                } else if let itemId = urlComponents?
                    .queryItems?
                    .first(where: { $0.name == "itemId" && $0.value != "nil" })?
                    .value {
                    navigator.push(.listRoute(listId: listId))
                    navigator.itemId = itemId
                } else {
                    navigator.push(.listRoute(listId: listId))
                }
            }
        case IxUniversalLinks.Sections.tasks:
            if let taskId = pathComponents[safe: 1] {
                navigator.navigateToTab(.tasks)
                navigator.taskId = taskId
            } else {
                navigator.navigateToTab(.tasks)
            }
        case IxUniversalLinks.Sections.settings:
            navigator.push(.settings)
        case IxUniversalLinks.Sections.quickAdd:
            guard let entity = pathComponents[safe: 1] else { return }
            switch entity {
            case IxUniversalLinks.QuickAddEntity.task.rawValue:
                navigator.navigateToTab(.tasks)
                navigator.taskCreatePresented = true
            case IxUniversalLinks.QuickAddEntity.item.rawValue:
                navigator.navigateToTab(.lists)
                navigator.itemCreatePresented = true
            default:
                log.warning("Received universal link for quick add for unknown entity: \(entity)")
            }
        default:
            return
        }
    }
}
