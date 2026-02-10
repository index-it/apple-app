//
//  EditTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct EditTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Task"

    static var parameterSummary: some ParameterSummary {
        Summary("Edit \(\.$task).") {
            \.$name
            \.$description
            \.$dueDate
            \.$priority
            \.$completed
        }
    }

    @Parameter(title: "Task", description: "The task to edit")
    var task: IxTaskEntity

    @Parameter(title: "Name")
    var name: String?

    @Parameter(title: "Description", description: "A description for the task")
    var description: String?

    @Parameter(title: "Due date", description: "The due date for the task")
    var dueDate: Date?

    @Parameter(title: "Priority", description: "The priority level for the task")
    var priority: Int?

    @Parameter(title: "Completed", description: "Whether the task is completed or not")
    var completed: Bool?

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxTaskEntity> & ProvidesDialog & ShowsSnippetIntent {
        let task = try await ixApiClient.editTask(
            taskId: task.id,
            name: name ?? task.name,
            description: description ?? task.description,
            dueDate: dueDate ?? task.dueDate,
            rrule: nil,
            reminders: [],
            subtasks: [],
            priority: priority ?? task.priority,
            itemId: nil
        )

        let modelContext = modelContainer.mainContext

        try modelContext.transaction {
            modelContext.insert(task)
        }

        let taskEntity = IxTaskEntity(task: task)
        try? await IxSystemIntegration.handleNewEntity(taskEntity)

        // full: read by the system when it cannot display the view
        // supporting: read before displaying the view
        let dialog = IntentDialog(
            full: "Task \(task.name) modified.",
            supporting: "Here's the modified task."
        )

        return .result(
            value: taskEntity,
            dialog: dialog,
            snippetIntent: TaskSnippetIntent(task: taskEntity)
        )
    }
}
