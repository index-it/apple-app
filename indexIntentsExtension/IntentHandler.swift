//
//  GenericHandler.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 21/02/26.
//

import Intents
import OSLog
import IxCoreKit
import SwiftData

private let log = Logger.intentLogger

class IntentHandler: INExtension, INAddTasksIntentHandling, INCreateNoteIntentHandling, INSendMessageIntentHandling {
    override func handler(for intent: INIntent) -> Any {
        log.info("Dispatching intent: \(intent)")
        return self
    }
    
    // MARK: - INSendMessageIntentHandling
    
    // Implement resolution methods to provide additional information about your intent (optional).
    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INSendMessageRecipientResolutionResult]) -> Void) {
        if let recipients = intent.recipients {
            
            // If no recipients were provided we'll need to prompt for a value.
            if recipients.count == 0 {
                completion([INSendMessageRecipientResolutionResult.needsValue()])
                return
            }
            
            var resolutionResults = [INSendMessageRecipientResolutionResult]()
            for recipient in recipients {
                let matchingContacts = [recipient] // Implement your contact matching logic here to create an array of matching contacts
                switch matchingContacts.count {
                case 2  ... Int.max:
                    // We need Siri's help to ask user to pick one from the matches.
                    resolutionResults += [INSendMessageRecipientResolutionResult.disambiguation(with: matchingContacts)]
                    
                case 1:
                    // We have exactly one matching contact
                    resolutionResults += [INSendMessageRecipientResolutionResult.success(with: recipient)]
                    
                case 0:
                    // We have no contacts matching the description provided
                    resolutionResults += [INSendMessageRecipientResolutionResult.unsupported()]
                    
                default:
                    break
                    
                }
            }
            completion(resolutionResults)
        } else {
            completion([INSendMessageRecipientResolutionResult.needsValue()])
        }
    }
    
    func resolveContent(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let text = intent.content, !text.isEmpty {
            completion(INStringResolutionResult.success(with: text))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    // Once resolution is completed, perform validation on the intent and provide confirmation (optional).
    
    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Verify user is authenticated and your app is ready to send a message.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .ready, userActivity: userActivity)
        completion(response)
    }
    
    // Handle the completed intent (required).
    
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Implement your application logic to send a message here.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .success, userActivity: userActivity)
        completion(response)
    }
    
    // MARK: ADD_TASK_INTENT
    func resolveTaskTitles(for intent: INAddTasksIntent) async -> [INSpeakableStringResolutionResult] {
        if let taskTitles = intent.taskTitles {
            return taskTitles.map { INSpeakableStringResolutionResult.success(with: $0) }
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
    
    // MARK: CREATE_NOTE_INTENT
    
    func resolveTitle(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult {
        if let title = intent.title {
            return INSpeakableStringResolutionResult.success(with: title)
        } else {
            return INSpeakableStringResolutionResult.needsValue()
        }
    }

    func resolveGroupName(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult {
        if let groupName = intent.groupName {
            return INSpeakableStringResolutionResult.success(with: groupName)
        } else {
            return INSpeakableStringResolutionResult.needsValue()
        }
    }

    func handle(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse {
        let ixApiClient = IxApiClient { _ in }
        guard let itemName = intent.title?.spokenPhrase else {
            return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }
        let itemNote = (intent.content as? INTextNoteContent)?.text

        guard let listName = intent.groupName?.spokenPhrase else {
            return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }

        do {
            let lists = try await MainActor.run {
                let modelContext = ModelContainerProvider.shared.mainContext
                return try modelContext.fetch(FetchDescriptor<IxList>())
            }

            var bestScore = 0.0
            var bestTrackIndex = -1

            for (i, list) in lists.enumerated() {
                let similarityScore = StringHelper.stringSimilarity(listName, list.name)
                if similarityScore > bestScore {
                    bestScore = similarityScore
                    bestTrackIndex = i
                }
            }

            guard let list = bestTrackIndex >= 0 ? lists[bestTrackIndex] : nil else {
                return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
            }

            let newItem = try await ixApiClient.createListItem(
                listId: list.id,
                categoryId: nil,
                name: itemName,
                link: nil,
                note: itemNote
            )

            await MainActor.run {
                let modelContext = ModelContainerProvider.shared.mainContext
                try? modelContext.transaction {
                    modelContext.insert(newItem)
                }
            }

            try? await IxSystemIntegration.handleNewEntity(IxListItemEntity(item: newItem))

            let response = INCreateNoteIntentResponse(code: .success, userActivity: nil)
            response.createdNote = INNote(
                title: INSpeakableString(spokenPhrase: itemName),
                contents: itemNote.map { [INTextNoteContent(text: $0)] } ?? [],
                groupName: INSpeakableString(spokenPhrase: list.name),
                createdDateComponents: DateHelper.localCalendar().dateComponents([.day, .month, .year, .hour, .minute], from: Date.now),
                modifiedDateComponents: nil,
                identifier: newItem.id
            )
            return response
        } catch {
            return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }
    }
}

