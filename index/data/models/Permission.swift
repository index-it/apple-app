//
//  Permission.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI

enum Permission {
    case list_viewer
    case list_editor
    case list_owner
    
    var localizedDescription: String {
        switch self {
        case .list_viewer:
            return NSLocalizedString("List viewer", comment: "Permission: list viewer")
        case .list_editor:
            return NSLocalizedString("List editor", comment: "Permission: list editor")
        case .list_owner:
            return NSLocalizedString("List owner", comment: "Permission: list owner")
        }
    }
}
