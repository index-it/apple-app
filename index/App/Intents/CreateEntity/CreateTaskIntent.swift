//
//  CreateTaskIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct CreateTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Create task"

    static var parameterSummary: some ParameterSummary {
        Summary("Create task \(\.$name)") {
            \.$description
            \.$dueDate
            \.$priority
            \.$time
        }
    }

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "Description", description: "A description for the task")
    var description: String?

    @Parameter(title: "Due date", description: "The due date for the task", kind: .date)
    var dueDate: Date?

    @Parameter(title: "Priority", description: "The priority level for the task")
    var priority: Int?

    @Parameter(title: "Time", description: "A time to set a reminder for the task", kind: .time)
    var time: Date?

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxTaskEntity> & ProvidesDialog & ShowsSnippetIntent {
        let task = try await ixApiClient.createTask(
            name: name,
            description: description,
            dueDate: dueDate,
            rrule: nil,
            reminders: time.map { [IxTaskReminder(daysBefore: 0, timeOffset: DateHelper.getUtcReminderTimeOffset($0))] } ?? [],
            subtasks: [],
            priority: priority,
            itemId: nil
        )

        let modelContext = modelContainer.mainContext

        let taskId = task.id
        try modelContext.transaction {
            try modelContext.delete(model: IxTask.self, where: #Predicate { $0.id == taskId })
            modelContext.insert(task)
        }

        let entity = IxTaskEntity(task: task)
        try? await IxSystemIntegration.handleNewEntity(entity)

        // full: read by the system when it cannot display the view
        // supporting: read before displaying the view
        let dialog = IntentDialog(
            full: "Created task \(task.name).",
            supporting: "Here's the created task."
        )

        return .result(
            value: entity,
            dialog: dialog,
            snippetIntent: TaskSnippetIntent(task: entity)
        )
    }
}
