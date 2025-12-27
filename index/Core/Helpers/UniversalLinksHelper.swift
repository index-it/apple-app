//
//  UniversalLinksHelper.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import Foundation
import os
import IxCoreKit

fileprivate let log = Logger(subsystem: IxSubsystems.APP, category: "UniversalLinksHelper")

struct UniversalLinksHelper {
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
            if let listId = pathComponents[safe: 1] {
                navigationManager.push(.listRoute(listId: listId))
            } else {
                navigationManager.navigateToTab(.lists)
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
