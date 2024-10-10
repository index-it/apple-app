//
//  NavigationManager.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation

class NavigationManager: ObservableObject {
    @Published var path: [NavigationRoute] = []
    
    func push(navigationRoute: NavigationRoute) {
        path.append(navigationRoute)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func clear() {
        path.removeAll()
    }
}
