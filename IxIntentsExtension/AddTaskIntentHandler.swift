//
//  AddTaskIntentHandler.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 08/02/26.
//

import Intents
import IxCoreKit
import SwiftData

class AddTaskIntentHandler: INExtension, INAddTasksIntentHandling {
    func resolveTaskTitles(for intent: INAddTasksIntent) async -> [INSpeakableStringResolutionResult] {
        if let taskTitles = intent.taskTitles {
            return taskTitles.map { INSpeakableStringResolutionResult.success(with: $0)}
        } else {
            return [INSpeakableStringResolutionResult.needsValue()]
        }
    }
    
    
    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse {
        guard let taskTitles = intent.taskTitles else {
            return INAddTasksIntentResponse(code: .failureRequiringAppLaunch, userActivity: nil)
        }
        let taskNames = taskTitles.map { $0.spokenPhrase }
        
        let dueDate = intent.temporalEventTrigger?.dateComponentsRange.startDateComponents.flatMap {
            DateHelper.utcDate(from: $0)
        }
        let rrule = intent.temporalEventTrigger?.dateComponentsRange.ekRecurrenceRule()?.lastRRuleString()
        let reminderTimeOffset = intent.temporalEventTrigger?.dateComponentsRange.startDateComponents.flatMap {
            DateHelper.getUtcReminderTimeOffset(from: $0)
        }
        
        let ixApiClient = IxApiClient { _ in }
        
        var tasksCreated: [IxTask] = []
        for taskName in taskNames {
            do {
                let task = try await ixApiClient.createTask(
                    name: taskName,
                    description: nil,
                    dueDate: dueDate,
                    rrule: rrule,
                    reminders: reminderTimeOffset.map { [IxTaskReminder(daysBefore: 0, timeOffset: $0)] } ?? [],
                    subtasks: [],
                    priority: nil,
                    itemId: nil
                )
                
                tasksCreated.append(task)
            } catch {
                return INAddTasksIntentResponse(code: .failureRequiringAppLaunch, userActivity: nil)
            }
        }
        
        await MainActor.run {
            let modelContext = ModelContainerProvider.shared.mainContext
            try? modelContext.transaction {
                for task in tasksCreated {
                    modelContext.insert(task)
                }
            }
        }
        
        try? await IxSystemIntegration.handleNewEntities(tasksCreated.map(IxTaskEntity.init))
 
        let response = INAddTasksIntentResponse(code: .success, userActivity: nil)
        response.addedTasks = tasksCreated.map {
            INTask(
                title: INSpeakableString(spokenPhrase: $0.name),
                status: .notCompleted,
                taskType: .completable,
                spatialEventTrigger: nil,
                temporalEventTrigger: intent.temporalEventTrigger,
                createdDateComponents: DateHelper.localCalendar().dateComponents([.year, .month, .day, .minute, .hour], from: Date.now),
                modifiedDateComponents: nil,
                identifier: $0.id
            )
        }
        return response
    }
}
