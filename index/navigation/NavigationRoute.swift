//
//  NavigationRoute.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation

enum NavigationRoute: Hashable {
    case listRoute(listId: String);
    case completedTasks;
    case accountSettings;
    case proSettings;
//    case GetPro
}
