//
//  CreateTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct CreateTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Create a new task"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create a new task with \(\.$name) and optionally a \(\.$description), \(\.$dueDate) and \(\.$priority)")
    }
    
    @Parameter(title: "Name")
    var name: String
    @Parameter(
        title: "Description",
        description: "Additional description for the task",
        inputOptions: .init(multiline: true)
    )
    var description: String?
    @Parameter(
        title: "Due date",
        description: "When the task should be completed",
        kind: .date
    )
    var dueDate: Date?
    @Parameter(
        title: "Time",
        description: "Time at which you will be reminded of the task",
        kind: .time
    )
    var time: Date
    @Parameter(title: "Priority")
    var priority: TaskPriority?
    
    

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxTaskEntity> {
        let task = try await ixApiClient.createTask(
            name: name,
            description: description,
            dueDate: dueDate,
            rrule: nil,
            reminders: [],
            subtasks: [],
            priority: priority?.rawValue,
            itemId: nil
        )
        
        let modelContext = modelContainer.mainContext
        
        try modelContext.transaction {
            modelContext.insert(task)
        }

        return .result(value: IxTaskEntity(task: task))
    }
}
