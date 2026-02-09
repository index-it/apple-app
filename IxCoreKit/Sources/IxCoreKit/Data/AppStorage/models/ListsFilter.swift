//
//  ListsFilter.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import Foundation

public enum ListsFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case ownedByMe
    case sharedWithMe

    public var id: Self {
        self
    }

    public var label: String {
        switch self {
        case .all:
            return NSLocalizedString("All", comment: "All lists filter")
        case .ownedByMe:
            return NSLocalizedString("Owned by me", comment: "Lists owned by the user")
        case .sharedWithMe:
            return NSLocalizedString("Shared with me", comment: "Lists shared with the user")
        }
    }
}
