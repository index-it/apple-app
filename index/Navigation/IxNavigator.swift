//
//  IxNavigator.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import Foundation

enum IxTab: Int, CaseIterable, Identifiable, Hashable {
    case tasks = 0
    case lists = 1
    
    var id: Int { rawValue }
}

enum IxNavRoute: Hashable {
    case archivedLists
    case listRoute(listId: String)
    case settings
    case accountSettings
    case proSettings
    case about
}

@Observable
class IxNavigator {
    // MARK: Tabs w/state
    var tab: IxTab = .lists
    
    var taskCreatePresented = false
    var taskId: String? = nil
    
    var itemCreatePresented = false
    var categoryId: String? = nil
    var itemId: String? = nil
    
    // MARK: NavigationStack routes
    var path: [IxNavRoute] = []

    func push(_ navRoute: IxNavRoute) {
        path.append(navRoute)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func clear() {
        path.removeAll()
    }
    
    func navigateToTab(_ tab: IxTab) {
        self.tab = tab
        // reset tabs state
        taskCreatePresented = false
        taskId = nil
        itemCreatePresented = false
        categoryId = nil
        itemId = nil
        // reset nav stack state
        clear()
    }
}
