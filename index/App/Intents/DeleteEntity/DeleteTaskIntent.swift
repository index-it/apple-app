//
//  DeleteTaskIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct DeleteTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Task"

    static var parameterSummary: some ParameterSummary {
        Summary("Delete\(\.$task).")
    }

    @Parameter(title: "Task", description: "The task to delete")
    var task: IxTaskEntity

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let taskId = task.id
        try? await ixApiClient.deleteTask(taskId: taskId)
        try? modelContainer.mainContext.delete(model: IxTask.self, where: #Predicate { $0.id == taskId })
        try? await IxSystemIntegration.handleEntityDeletion(taskId, of: IxTaskEntity.self)

        return .result(
            dialog: "\(task.name) deleted."
        )
    }
}
