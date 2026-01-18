//
//  TasksFilter.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import Foundation

public enum TasksFilter: String, CaseIterable, Identifiable {
    case completed
    case uncompleted

    public var id: Self { self }

    public var label: String {
        switch self {
        case .completed:
            return NSLocalizedString("Completed", comment: "Filter for completed tasks")
        case .uncompleted:
            return NSLocalizedString("Uncompleted", comment: "Filter for uncompleted tasks")
        }
    }
}
