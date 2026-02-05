//
//  IxTaskEntity.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents

@available(iOS 26.0, *)
struct IxTaskEntity: IndexedEntity {
    static let defaultQuery = IxTaskEntityQuery()
    
    var id: String
    
    @Property(indexingKey: \.title)
    var name: String
    
    @Property(indexingKey: \.contentDescription)
    var description: String
    
    @Property
    var completed: Bool
    
    @Property
    var dueDate: Date?
    
    @Property
    var priority: Int?
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Task", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) tasks"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    init(task: IxTask) {
        self.id = task.id
        self.name = task.name
        self.completed = task.completed
        self.dueDate = task.dueDate
        self.priority = task.priority
    }
}

@available(iOS 26.0, *)
extension IxTaskEntity: URLRepresentableEntity {
    static var urlRepresentation: URLRepresentation {
        "https://web.index-it.app/tasks/\(.id)"
    }
}
