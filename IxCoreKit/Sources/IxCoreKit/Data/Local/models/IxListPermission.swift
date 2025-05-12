//
//  Permission.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI

public enum IxListPermission: Sendable {
    case viewer
    case editor
    case owner
    
    public var localizedDescription: String {
        switch self {
        case .viewer:
            return NSLocalizedString("List viewer", comment: "Permission: list viewer")
        case .editor:
            return NSLocalizedString("List editor", comment: "Permission: list editor")
        case .owner:
            return NSLocalizedString("List owner", comment: "Permission: list owner")
        }
    }
}
