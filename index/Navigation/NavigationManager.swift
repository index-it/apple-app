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
    @Published var quickAddTaskViewPresented: Bool = false
    @Published var quickAddItemViewPresented: Bool = false

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
        quickAddItemViewPresented = false
        quickAddTaskViewPresented = false
        
        selectedHomeTab = homeTab
        clear()
    }
    
    func showQuickAddTaskView() {
        selectedHomeTab = .tasks
        clear()
        quickAddTaskViewPresented = true
    }
    
    func showQuickAddItemView() {
        selectedHomeTab = .lists
        clear()
        quickAddItemViewPresented = true
    }
}
