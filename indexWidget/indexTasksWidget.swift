//
//  indexTasksWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/03/25.
//

import SwiftUI
import WidgetKit
import SwiftData

struct TodayTasksWidget: Widget {
    let kind: String = IxKinds.tasksWidget
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: TodayTasksProvider()
        ) { entry in
            TodayTasksWidgetView(entry: entry)
                .widgetURL(URL(string: "https://web.index-it.app/tasks")!)
        }
        .configurationDisplayName("Today's Tasks")
        .description("Shows your tasks due today")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct TodayTasksEntry: TimelineEntry {
    let date: Date
    let tasks: [IxTask]
}

struct TodayTasksWidgetView : View {
    var entry: TodayTasksProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.openURL) var openUrl
    
    var body: some View {
        tasksView
            .containerBackground(.background, for: .widget)
    }
    
    @ViewBuilder
    var tasksView: some View {
        switch widgetFamily {
        case .systemSmall:
            systemSmallView
        case .systemMedium:
            systemMediumView
        case .systemLarge:
            systemLargeView
        default:
            systemSmallView
        }
    }
    
    @ViewBuilder
    var systemSmallView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Today")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text("\(entry.tasks.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
            }
            
            if entry.tasks.isEmpty {
                Text("No Tasks")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                tasksListView(entry.tasks.prefix(3))
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var systemMediumView: some View {
        HStack {
            VStack {
                createTaskButtonView
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("\(entry.tasks.count)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                    Text("Today")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            
            if entry.tasks.isEmpty {
                HStack {
                    Spacer()
                    Text("No Tasks")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                Spacer(minLength: 16)
                VStack(alignment: .leading) {
                    tasksListView(entry.tasks.prefix(4))
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var systemLargeView: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.tasks.count)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                    Text("Today")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
                
                Spacer()
                
                createTaskButtonView
            }
            
            Divider()
            
            if entry.tasks.isEmpty {
                VStack {
                    Spacer()
                    Text("No Tasks")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else {
                Spacer(minLength: 10)
                
                VStack(alignment: .leading) {
                    tasksListView(entry.tasks.prefix(7))
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var createTaskButtonView: some View {
        Button(intent: CreateTaskIntent()) {
            Label("Create", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
    }
    
    @ViewBuilder
    func tasksListView(_ tasks: ArraySlice<IxTask>) -> some View {
        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
            HStack {
                Button(intent: CompleteTaskIntent(taskId: task.id)) {
                    Label("Complete", systemImage: task.completed ? "inset.filled.circle" : "circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }.buttonStyle(.plain)
                    
                
                Text(task.name)
                    .lineLimit(1)
                    .font(.footnote)
                
                Spacer()
            }
            
            
            if index != tasks.count - 1 {
                Divider()
                    .padding(.leading, 32)
            }
        }
    }
}

struct TodayTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTasksEntry {
        TodayTasksEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayTasksEntry) -> ()) {
        // Get sample data for preview
        let entry = TodayTasksEntry(
            date: Date.now,
            tasks: [
                IxTask(id: "1", userId: "1", itemId: nil, name: "Buy Gocciole", description: nil, subtasks: [], dueDate: Date.now, rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil),
                IxTask(id: "2", userId: "1", itemId: nil, name: "Clean windsurf", description: nil, subtasks: [], dueDate: Date.now, rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil)
            ]
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksEntry>) -> ()) {
        Task { @MainActor in
            var tasks: [IxTask] = []
            
            let modelContext = ModelContext(ModelContainerProvider.shared)
            
            // Create a predicate for today's tasks
            var calendar = Calendar.current
//            calendar.timeZone = TimeZone(identifier: "UTC")!
            let now = Date.now.toLocalDate()

            let predicate = #Predicate<IxTask> {
                !$0.completed
            }
            
            let descriptor = FetchDescriptor<IxTask>(predicate: predicate, sortBy: [SortDescriptor(\IxTask.priority)])
            
            do {
                tasks = try modelContext.fetch(descriptor)
            } catch {
                print("Failed to fetch tasks: \(error)")
            }
            
            // Create the timeline entry with fetched tasks
            let entry = TodayTasksEntry(date: Date(), tasks: tasks.filter({
                $0.due_date == nil || calendar.compare($0.due_date!, to: now, toGranularity: .day).rawValue <= 0
            }))
            
            // Update every hour or when the widget refreshes
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}

struct TodayTasksWidget_Previews: PreviewProvider {
    static var tasks = [
        IxTask(id: "1", userId: "1", itemId: nil, name: "Buy Gocciole", description: nil, subtasks: [], dueDate: Date.now, rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil)
    ]
    static var previews: some View {
        TodayTasksWidgetView(entry: TodayTasksEntry(
            date: Date(),
            tasks: tasks
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        TodayTasksWidgetView(entry: TodayTasksEntry(
            date: Date(),
            tasks: tasks
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        TodayTasksWidgetView(entry: TodayTasksEntry(
            date: Date(),
            tasks: tasks
        ))
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
