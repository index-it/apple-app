//
//  TaskSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import Foundation

public enum TasksSorting: String, CaseIterable, Identifiable, Sendable {
    case name
    case priority
    case creation
    case manual
        
    public var id: Self { self }
    
    public var label: String {
        switch self {
        case .name:
            return NSLocalizedString("Name", comment: "Sort tasks by name")
        case .priority:
            return NSLocalizedString("Priority", comment: "Sort tasks by priority")
        case .creation:
            return NSLocalizedString("Creation date", comment: "Sort tasks by creation date")
        case .manual:
            return NSLocalizedString("Manual", comment: "Sort tasks manually")
        }
    }
}
