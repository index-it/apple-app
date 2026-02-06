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
    static func handleUniversalLink(_ url: URL, navigationManager: NavigationManager) {
        if url.host() != "web.index-it.app" {
            navigationManager.navigateToTab(.tasks)
            return
        }

        // Extract the path components, ignoring the domain for Universal Links
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard pathComponents.count >= 1 else { return }

        let section = pathComponents[0]

        switch section {
        case IxUniversalLinks.Sections.lists:
            navigationManager.navigateToTab(.lists)
            
            if let listId = pathComponents[safe: 1] {
                if let categoriesSection = pathComponents[safe: 2],
                   categoriesSection == IxUniversalLinks.Sections.categories,
                   let categoryId = pathComponents[safe: 3] {
                    navigationManager.push(.listRoute(listId: listId, categoryId: categoryId))
                } else {
                    navigationManager.push(.listRoute(listId: listId, categoryId: nil))
                }
            }
        case IxUniversalLinks.Sections.tasks:
            navigationManager.navigateToTab(.tasks)
        case IxUniversalLinks.Sections.settings:
            navigationManager.push(.settings)
        case IxUniversalLinks.Sections.quickAdd:
            guard let entity = pathComponents[safe: 1] else { return }
            switch entity {
            case IxUniversalLinks.QuickAddEntity.task.rawValue:
                navigationManager.showQuickAddTaskView()
            case IxUniversalLinks.QuickAddEntity.item.rawValue:
                navigationManager.showQuickAddItemView()
            default:
                log.warning("Received universal link for quick add for unknown entity: \(entity)")
            }
        default:
            return
        }
    }
}
