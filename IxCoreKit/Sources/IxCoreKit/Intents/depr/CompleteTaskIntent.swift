//
//  CompleteTaskIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import AppIntents
import SwiftData

public struct CompleteTaskIntent: DeprecatedAppIntent {
    public static var title: LocalizedStringResource {
        return "Complete Task"
    }

    public static var description: IntentDescription {
        return IntentDescription("Completes a task.")
    }

    @Parameter(title: "Task id")
    var taskId: String

    public init(taskId: String) {
        self.taskId = taskId
    }

    public init() {}

    public func perform() async throws -> some IntentResult {
        if taskId.isEmpty {
            return .result()
        }

        let ixApiClient = IxApiClient { _ in }
        let modelContext = await ModelContext(ModelContainerProvider.shared)
        if #available(iOS 18, *) {
            modelContext.author = "widget"
        }

        let task = try await ixApiClient.setTaskCompletion(taskId: taskId, completed: true)

        try modelContext.transaction {
            modelContext.insert(task)
        }

        WidgetHelper.reloadTasksWidget()

        return .result()
    }
}
