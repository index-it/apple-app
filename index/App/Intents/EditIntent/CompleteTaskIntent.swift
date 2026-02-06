//
//  CompleteTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct CompleteTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete a task"

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$task)")
    }

    @Parameter var task: IxTaskEntity

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient
    
    init() {}
    init(task: IxTaskEntity) {
        self.task = task
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxTaskEntity> {
        let task = try await ixApiClient.setTaskCompletion(taskId: task.id, completed: true)
        let taskId = task.id

        let modelContext = modelContainer.mainContext
        
        try modelContext.transaction {
            try modelContext.delete(model: IxTask.self, where: #Predicate { $0.id == taskId })
            modelContext.insert(task)
        }

        WidgetHelper.reloadTasksWidget()

        return .result(value: IxTaskEntity(task: task))
    }
}
