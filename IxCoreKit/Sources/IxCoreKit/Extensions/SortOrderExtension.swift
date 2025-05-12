//
//  SortOrderExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 07/05/25.
//

import Foundation

public extension SortOrder {
    var labelForCreationDate: String {
        switch self {
        case .forward:
            return NSLocalizedString("Oldest First", comment: "forward sort order for creation date")
        case .reverse:
            return NSLocalizedString("Newest First", comment: "reverse sort order for creation date")
        }
    }
    
    var labelForPriority: String {
        switch self {
        case .forward:
            return NSLocalizedString("Highest First", comment: "forward sort order for priority")
        case .reverse:
            return NSLocalizedString("Lowest First", comment: "reverse sort order for priority")
        }
    }
    
    var labelForName: String {
        switch self {
        case .forward:
            return NSLocalizedString("Ascending", comment: "forward sort order for name")
        case .reverse:
            return NSLocalizedString("Descending", comment: "reverse sort order for name")
        }
    }
}
