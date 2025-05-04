//
//  SortingOrder.swift
//  IxDataKit
//
//  Created by Giulio Pimenoff Verdolin on 28/04/25.
//

import Foundation

public enum SortingOrder: CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst
    
    public var id: Self { self }
    
    public var label: String {
        switch self {
        case .newestFirst:
            return NSLocalizedString("Newest first", comment: "Sort items by newest first")
        case .oldestFirst:
            return NSLocalizedString("Oldest first", comment: "Sort items by oldest first")
        }
    }
}
