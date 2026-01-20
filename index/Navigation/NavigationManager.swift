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

    @Published var quickAddTaskViewMulti: Bool = false
    @Published var quickAddTaskViewPresented: Bool = false
    @Published var quickAddItemViewMulti: Bool = false
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

    func showQuickAddTaskView(multi: Bool = false) {
        selectedHomeTab = .tasks
        clear()
        quickAddTaskViewMulti = multi
        quickAddTaskViewPresented = true
    }

    func showQuickAddItemView(multi: Bool = false) {
        selectedHomeTab = .lists
        clear()
        quickAddItemViewMulti = multi
        quickAddItemViewPresented = true
    }
}
