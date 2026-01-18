//
//  AuthNavigationManager.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/10/24.
//

import Foundation

class AuthNavigationManager: ObservableObject {
    @Published var path: [AuthNavigationRoute] = []

    func push(_ navigationRoute: AuthNavigationRoute) {
        path.append(navigationRoute)
    }

    func pop() {
        _ = path.popLast()
    }

    func clear() {
        path.removeAll()
    }
}
