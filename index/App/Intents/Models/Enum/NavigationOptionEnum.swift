//
//  NavigationOptionEnum.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

enum NavigationOptionEnum: String, Hashable, Identifiable, CaseIterable, AppEnum {
    case tasks
    case lists
    case createTask
    case createItem

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(
            name: LocalizedStringResource("Navigation Option", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) navigation options"
        )
    }

    static var caseDisplayRepresentations: [NavigationOptionEnum: DisplayRepresentation] = [
        .lists: DisplayRepresentation(title: "Lists", image: .init(systemName: "square.grid.2x2")),
        .tasks: DisplayRepresentation(title: "Tasks", image: .init(systemName: "rectangle.grid.1x2")),
        .createTask: DisplayRepresentation(title: "Create task", image: .init(systemName: "calendar.badge.plus")),
        .createItem: DisplayRepresentation(title: "Create item", image: .init(systemName: "note.text.badge.plus")),
    ]

    var id: String {
        rawValue
    }

    var url: URL {
        switch self {
        case .lists:
            return URL(string: IxUniversalLinks.lists)!
        case .tasks:
            return URL(string: IxUniversalLinks.tasks)!
        case .createItem:
            return URL(string: IxUniversalLinks.quickAdd(.item))!
        case .createTask:
            return URL(string: IxUniversalLinks.quickAdd(.task))!
        }
    }
}
