//
//  NextTaskTimeline.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/02/26.
//

import IxCoreKit
import WidgetKit
import SwiftData

struct NextTaskEntry: TimelineEntry {
    let date: Date
    let task: IxTask?
}

struct NextTaskTimelineProvider: AppIntentTimelineProvider {
    /// Used when the widget is loading
    func placeholder(in _: Context) -> NextTaskEntry {
        NextTaskEntry(date: Date(), task: nil)
    }
    
    /// Used by widget previews when the user scrolls the available widgets
    func snapshot(for configuration: NextTaskConfigurationWidgetIntent, in context: Context) async -> NextTaskEntry {
        return NextTaskEntry(
            date: Date.now,
            task: .mock(name: "Wax Skis")
        )
    }
    
    func timeline(for configuration: NextTaskConfigurationWidgetIntent, in context: Context) async -> Timeline<NextTaskEntry> {
        let task = Task { @MainActor in
            var tasks: [IxTask] = []
            let modelContext = ModelContext(ModelContainerProvider.shared)
            
            let predicate: Predicate<IxTask>
            if let minimumPriority = configuration.minimumPriority?.rawValue {
                predicate = #Predicate<IxTask> {
                    !$0.completed && ($0.priority ?? 0) >= minimumPriority
                }
            } else {
                predicate = #Predicate<IxTask> {
                    !$0.completed
                }
            }
            
            let descriptor = FetchDescriptor<IxTask>(
                predicate: predicate,
                sortBy: [
                    SortDescriptor(\IxTask.dueDate),
                    SortDescriptor(\IxTask.priority, order: .reverse),
                    SortDescriptor(\IxTask.createdAt, order: .reverse),
                    SortDescriptor(\IxTask.editedAt, order: .reverse),
                ]
            )
            
            do {
                tasks = try modelContext.fetch(descriptor)
                if !configuration.allowNonScheduled {
                    tasks = tasks.filter { $0.dueDate != nil }
                }
                tasks = tasks.filter {
                    if let dueDate = $0.dueDate {
                        (DateHelper.calendar().dateComponents([.day], from: .now, to: dueDate).day ?? 0) <= configuration.maxDaysAhead
                    } else {
                        false
                    }
                }
            } catch {
                print("Failed to fetch tasks: \(error)")
            }
            
            let nextTask = tasks.first
            
            let entry = NextTaskEntry(
                date: Date.now,
                task: nextTask
            )
            
            // Update every hour or when the widget refreshes
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        }
        
        return await task.value
    }
}
