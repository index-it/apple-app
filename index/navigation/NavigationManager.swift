//
//  NavigationManager.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation

class NavigationManager: ObservableObject {
    @Published var path: [NavigationRoute] = []
    @Published var selectedHomeTab: HomeTab = .lists
    @Published var showCreateTaskSheet = false
    @Published var showCreateItemSheet = false

    func push(navigationRoute: NavigationRoute) {
        path.append(navigationRoute)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func clear() {
        path.removeAll()
    }
    
    func navigateToTab(_ homeTab: HomeTab, showCreateSheet: Bool = false) {
        selectedHomeTab = homeTab
        showCreateItemSheet = false
        showCreateTaskSheet = false
        
        if showCreateSheet {
            if homeTab == .lists {
                showCreateItemSheet = showCreateSheet
            } else if homeTab == .tasks {
                showCreateTaskSheet = showCreateSheet
            }
        }
        
        clear()
    }
}
