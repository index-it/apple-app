//
//  EntityType.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI

public enum EntityType: Sendable {
    case list
    case category
    case item
    case task
    case user
    case selfUser
    case proSubscription

    public var localizedDescription: String {
        switch self {
        case .list:
            return NSLocalizedString("List", comment: "Entity type: List")
        case .category:
            return NSLocalizedString("Category", comment: "Entity type: Category")
        case .item:
            return NSLocalizedString("Item", comment: "Entity type: Item")
        case .task:
            return NSLocalizedString("Task", comment: "Entity type: Task")
        case .user:
            return NSLocalizedString("User", comment: "Entity type: User")
        case .selfUser:
            return NSLocalizedString("You", comment: "Entity type: Self User, referring to the current logged-in user")
        case .proSubscription:
            return NSLocalizedString("Pro subscription", comment: "Entity type: Pro Subscription")
        }
    }
}
