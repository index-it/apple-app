//
//  ListsSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import Foundation

public enum ListsSorting: String, CaseIterable, Identifiable, Sendable {
    case name
    case creationDate
    case manual
        
    public var id: Self { self }
    
    public var label: String {
        switch self {
        case .name:
            return NSLocalizedString("Name", comment: "Sort lists by name")
        case .creationDate:
            return NSLocalizedString("Creation date", comment: "Sort lists by creation date")
        case .manual:
            return NSLocalizedString("Manual", comment: "Sort lists manually")
        }
    }
}
