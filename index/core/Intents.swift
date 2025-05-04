//
//  Intents.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/03/25.
//

import AppIntents
import SwiftUI
import SwiftData
import WidgetKit
import IxCoreKit

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description: IntentDescription = "Create a new task"
    
    func perform() async throws -> some IntentResult & OpensIntent {
        // Construct the URL to open the app on the create task page
        guard let url = URL(string: "https://web.index-it.app/create-task") else {
            throw URLError(.badURL)
        }
        
        return .result(opensIntent: OpenURLIntent(url))
    }
    
    static var openAppWhenRun: Bool = true
}

struct CreateListItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Create List Item"
    static var description: IntentDescription = "Create a new list item"
    
    func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: "https://web.index-it.app/create-item") else {
            throw URLError(.badURL)
        }
        
        return .result(opensIntent: OpenURLIntent(url))
    }
    
    static var openAppWhenRun: Bool = true
}

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource {
        return "Complete Task"
    }
    static var description: IntentDescription {
        return IntentDescription("Completes a task.")
    }
    
    @Parameter(title: "Task id")
    var taskId: String
    
    init(taskId: String) {
        self.taskId = taskId
    }
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        if (taskId.isEmpty) {
            return .result()
        }
        
        let ixApiClient = IxApiClient()
        let modelContext = await ModelContext(ModelContainerProvider.shared)
        modelContext.author = "widget"
        
        let task = try await ixApiClient.setTaskCompletion(taskId: taskId, completed: true)

        try modelContext.transaction {
            modelContext.insert(task)
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        
        return .result()
    }
}
