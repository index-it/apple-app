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
struct CompleteTaskByIdIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete a task via its id"
    static var isDiscoverable: Bool = false
    static var supportedModes: IntentModes = .background

    @Parameter(title: "Task id")
    var taskId: String

    @Dependency var modelContainer: ModelContainer
    @Dependency var ixApiClient: IxApiClient
    
    init() {}
    
    init(taskId: String) {
        self.taskId = taskId
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IxTaskEntity> {
        let task = try await ixApiClient.setTaskCompletion(taskId: taskId, completed: true)
        
        let modelContext = modelContainer.mainContext
        try modelContext.transaction {
            try modelContext.delete(model: IxTask.self, where: #Predicate { $0.id == taskId })
            modelContext.insert(task)
        }
        
        try? await IxSystemIntegration.handleNewEntity(IxTaskEntity(task: task))
        
        return .result(value: IxTaskEntity(task: task))
    }
}
