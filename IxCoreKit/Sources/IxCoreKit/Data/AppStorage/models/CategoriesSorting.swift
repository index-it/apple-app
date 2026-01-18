//
//  CategoriesSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/12/24.
//

import Foundation

public enum CategoriesSorting: String, CaseIterable, Identifiable, Sendable {
    case name
    case creationDate
//    case manual

    public var id: Self { self }

    public var label: String {
        switch self {
        case .name:
            return NSLocalizedString("Name", comment: "Sort categories by name")
        case .creationDate:
            return NSLocalizedString("Creation date", comment: "Sort categories by creation date")
//        case .manual:
//            return NSLocalizedString("Manual", comment: "Sort categories manually")
        }
    }
}
