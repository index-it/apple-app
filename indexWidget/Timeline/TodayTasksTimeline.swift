//
//  TodayTasksProvider.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import IxCoreKit
import WidgetKit
import SwiftData

struct TodayTasksEntry: TimelineEntry {
    let date: Date
    let relevance: TimelineEntryRelevance?
    let tasks: [IxTask]
}

struct TodayTasksProvider: TimelineProvider {
    /// Used when the widget is loading
    func placeholder(in _: Context) -> TodayTasksEntry {
        TodayTasksEntry(date: Date(), relevance: nil, tasks: [])
    }
    
    /// Used by widget previews when the user scrolls the available widgets
    func getSnapshot(in _: Context, completion: @escaping (TodayTasksEntry) -> Void) {
        let entry = TodayTasksEntry(
            date: Date.now,
            relevance: nil,
            tasks: [
                IxTask(id: "1", userId: "1", itemId: nil, name: "Buy Gocciole", description: nil, subtasks: [], dueDate: Date.now, rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.timeMillis(), completedAt: nil),
                IxTask(id: "2", userId: "1", itemId: nil, name: "Clean windsurf", description: nil, subtasks: [], dueDate: Date.now, rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.timeMillis(), completedAt: nil),
            ]
        )
        completion(entry)
    }
    
    func getTimeline(in _: Context, completion: @escaping (Timeline<TodayTasksEntry>) -> Void) {
        Task { @MainActor in
            var tasks: [IxTask] = []
            
            let modelContext = ModelContext(ModelContainerProvider.shared)
            
            // Create a predicate for today's tasks
            let calendar = DateHelper.localCalendar()
            let now = Date.now
            
            let predicate = #Predicate<IxTask> {
                !$0.completed
            }
            
            let descriptor = FetchDescriptor<IxTask>(predicate: predicate, sortBy: [SortDescriptor(\IxTask.priority, order: .reverse)])
            
            do {
                tasks = try modelContext.fetch(descriptor)
            } catch {
                print("Failed to fetch tasks: \(error)")
            }
            
            let todayTasks = tasks.filter {
                $0.dueDate != nil && calendar.compare($0.dueDate!, to: now, toGranularity: .day).rawValue <= 0
            }
            let remindersInThisHour = todayTasks
                .flatMap { $0.reminders }
                .map { $0.asDate(taskDueDate: Date.now) }
                .filter {
                    DateHelper.calendar().compare($0, to: Date.now, toGranularity: .hour) == .orderedSame
                }
                .count
            
            let relevanceScore: IxTimelineEntryRelevance = remindersInThisHour >= 3 ? .high : (remindersInThisHour > 0 ? .medium : .low)
            let relevance = TimelineEntryRelevance(score: relevanceScore.rawValue)
            
            let entry = TodayTasksEntry(
                date: Date.now,
                relevance: relevance,
                tasks: todayTasks
            )
            
            // Update every hour or when the widget refreshes
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}
