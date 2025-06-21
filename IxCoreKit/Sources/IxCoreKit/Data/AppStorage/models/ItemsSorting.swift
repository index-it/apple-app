//
//  ItemsSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 30/12/24.
//

import Foundation

public enum ItemsSorting: String, CaseIterable, Identifiable, Sendable {
    case name
    case creationDate
//    case manual
    
    public var id: Self { self }
    
    public var label: String {
        switch self {
        case .name:
            return NSLocalizedString("Name", comment: "Sort items by name")
        case .creationDate:
            return NSLocalizedString("Creation date", comment: "Sort items by creation date")
//        case .manual:
//            return NSLocalizedString("Manual", comment: "Sort items manually")
        }
    }
}
