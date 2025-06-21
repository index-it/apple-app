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
            return NSLocalizedString("Lowest First", comment: "forward sort order for priority")
        case .reverse:
            return NSLocalizedString("Highest First", comment: "reverse sort order for priority")
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
    
    func labelForListsSorting(_ sorting: ListsSorting) -> String {
        switch sorting {
//        case .manual:
//            return ""
        case .creationDate:
            return labelForCreationDate
        case .name:
            return labelForName
        }
    }
    
    func labelForCategoriesSorting(_ sorting: CategoriesSorting) -> String {
        switch sorting {
//        case .manual:
//            return ""
        case .name:
            return labelForName
        case .creationDate:
            return labelForCreationDate
        }
    }
    
    func labelForItemsSorting(_ sorting: ItemsSorting) -> String {
        switch sorting {
//        case .manual:
//            return ""
        case .name:
            return labelForName
        case .creationDate:
            return labelForCreationDate
        }
    }
    
    func labelForTasksSorting(_ sorting: TasksSorting) -> String {
        switch sorting {
//        case .manual:
//            return ""
        case .name:
            return labelForName
        case .priority:
            return labelForPriority
        case .creation:
            return labelForCreationDate
        }
    }
}
