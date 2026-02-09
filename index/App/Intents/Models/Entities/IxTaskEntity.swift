//
//  IxTaskEntity.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents
import IxCoreKit

@available(iOS 26.0, *)
struct IxTaskEntity: IndexedEntity {
    public static let defaultQuery = IxTaskEntityQuery()
    
    public var id: String
    
    @Property(indexingKey: \.title)
    public var name: String
    
    @Property(indexingKey: \.contentDescription)
    public var description: String
    
    @Property
    public var completed: Bool
    
    @Property
    public var dueDate: Date?
    
    @Property
    public var priority: Int?
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Task", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) tasks"
        )
    }
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public init(task: IxTask) {
        self.id = task.id
        self.name = task.name
        self.completed = task.completed
        self.dueDate = task.dueDate
        self.priority = task.priority
    }
}

@available(iOS 26.0, *)
extension IxTaskEntity: URLRepresentableEntity {
    public static var urlRepresentation: URLRepresentation {
        "https://web.index-it.app/tasks/\(.id)"
    }
}
