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

    func push(_ navigationRoute: NavigationRoute) {
        path.append(navigationRoute)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func clear() {
        path.removeAll()
    }
    
    func navigateToTab(_ homeTab: HomeTab) {
        selectedHomeTab = homeTab
        
        clear()
    }
}
