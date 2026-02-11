//
//  TodayTasksProgressTimeline.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/02/26.
//

import IxCoreKit
import WidgetKit
import SwiftData

struct TodayTasksProgressEntry: TimelineEntry {
    let date: Date
    let total: Int
    let completed: Int
}

struct TodayTasksProgressTimelineProvider: TimelineProvider {
    /// Used when the widget is loading
    func placeholder(in _: Context) -> TodayTasksProgressEntry {
        TodayTasksProgressEntry(date: .now, total: 0, completed: 0)
    }
    
    /// Used by widget previews when the user scrolls the available widgets
    func getSnapshot(in _: Context, completion: @escaping (TodayTasksProgressEntry) -> Void) {
        completion(TodayTasksProgressEntry(date: .now, total: 6, completed: 4))
    }
    
    func getTimeline(in _: Context, completion: @escaping (Timeline<TodayTasksProgressEntry>) -> Void) {
        Task { @MainActor in
            var tasks: [IxTask] = []
            
            let modelContext = ModelContext(ModelContainerProvider.shared)
            
            let calendar = DateHelper.calendar()
            let now = Date.now
            let startOfDayMillis = DateHelper.localCalendar().startOfDay(for: now).timeMillis()
            let currentTimeMillis = now.timeMillis()
            
            let predicate = #Predicate<IxTask> {
                if let completedAt = $0.completedAt {
                    return completedAt >= startOfDayMillis && completedAt <= currentTimeMillis
                } else {
                    return $0.dueDate != nil
                }
            }
            
            let descriptor = FetchDescriptor<IxTask>(predicate: predicate)
            
            do {
                let fetchedTasks = try modelContext.fetch(descriptor)
                
                tasks = fetchedTasks.filter {
                    if $0.completed {
                        return true
                    } else {
                        return $0.dueDate != nil && calendar.compare($0.dueDate!, to: now, toGranularity: .day).rawValue <= 0
                    }
                }
            } catch {
            }
            
            let total = tasks.count
            let completed = tasks.filter { $0.completed }.count
            
            let entry = TodayTasksProgressEntry(
                date: Date.now,
                total: total,
                completed: completed
            )
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}
