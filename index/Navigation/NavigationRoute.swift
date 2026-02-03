//
//  NavigationRoute.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation

enum NavigationRoute: Hashable {
    case archivedLists
    case listRoute(listId: String, categoryId: String?)
    case settings
    case accountSettings
    case proSettings
    case about
}
