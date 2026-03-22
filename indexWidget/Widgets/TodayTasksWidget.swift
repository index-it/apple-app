//
//  indexTasksWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/03/25.
//

import AppIntents
import IxCoreKit
import SwiftData
import SwiftUI
import WidgetKit

struct TodayTasksWidget: Widget {
    let kind: String = IxKinds.todayTasksWidget
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: TodayTasksProvider()
        ) { entry in
            TodayTasksWidgetView(entry: entry)
                .widgetURL(URL(string: IxUniversalLinks.tasks)!)
        }
        .configurationDisplayName("Today's Tasks")
        .description("Shows your tasks due today")
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .systemExtraLarge,
                .accessoryCircular,
                .accessoryInline,
                .accessoryRectangular
            ]
        )
    }
}



struct TodayTasksWidgetView: View {
    var entry: TodayTasksProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        tasksView
            .containerBackground(.background, for: .widget)
//            .task {
//                await IxWidgetDependencies.setup()
//            }
    }
    
    @ViewBuilder
    var tasksView: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryInline:
            accessoryInlineView
        case .accessoryRectangular:
            accessoryRectangularView
        case .systemSmall:
            systemSmallView
        case .systemMedium:
            systemMediumView
        case .systemLarge:
            systemLargeView
        default:
            systemLargeView
        }
    }
    
    var accessoryCircularView: some View {
        ZStack {
            // https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background
            AccessoryWidgetBackground()
            
            if entry.tasks.isEmpty {
                Text("No\nTasks")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            } else {
                VStack {
                    Text("\(entry.tasks.count)")
                        .fontWeight(.semibold)
                    Text("Tasks")
                }
            }
        }
    }
    
    var accessoryInlineView: some View {
        HStack {
            Image(systemName: "list.bullet")
            
            if entry.tasks.isEmpty {
                Text("No Tasks Due Today")
            } else if entry.tasks.count == 1, let task = entry.tasks.first {
                Text(task.name)
            } else {
                Text("\(entry.tasks.count) Tasks Today")
            }
        }
    }
    
    var accessoryRectangularView: some View {
        VStack(alignment: .leading) {
            if entry.tasks.isEmpty {
                Text("Today")
                    .fontWeight(.bold)
                Text("No Tasks")
            } else {
                if entry.tasks.count < 3 {
                    Text("Today")
                        .fontWeight(.bold)
                }
                
                ForEach(entry.tasks.prefix(3), id: \.id) { task in
                    HStack(spacing: 6) {
                        Button(intent: CompleteTaskByIdIntent(taskId: task.id)) {
                            Image(systemName: task.completed ? "inset.filled.circle" : "circle")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Text(task.name)
                            .lineLimit(1)
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth:. infinity)
    }
    
    var systemSmallView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Today")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                    .widgetAccentable()
                Spacer()
                Text("\(entry.tasks.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
                    .widgetAccentable()
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
                        .widgetAccentable()
                    Text("Today")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .widgetAccentable()
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
        }
    }
    
    var systemLargeView: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.tasks.count)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .widgetAccentable()
                    Text("Today")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .widgetAccentable()
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
        }
    }
    
    var createTaskButtonView: some View {
        Button(intent: NavigateIntent(navigationOption: NavigationOptionEnum.createTask)) {
            Label("Create", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
    }
    
    func tasksListView(_ tasks: ArraySlice<IxTask>) -> some View {
        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
            HStack {
                Button(intent: CompleteTaskByIdIntent(taskId: task.id)) {
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


struct TodayTasksWidget_Previews: PreviewProvider {

    static let tasks: [IxTask] = [
        IxTask(
            id: "1",
            userId: "1",
            itemId: nil,
            name: "Buy Gocciole",
            description: nil,
            subtasks: [],
            dueDate: .now,
            rrule: nil,
            completed: false,
            priority: nil,
            reminders: [],
            createdAt: Date.now.timeMillis(),
            completedAt: nil
        )
    ]

    static let entry = TodayTasksEntry(
        date: .now,
        relevance: nil,
        tasks: tasks
    )

    static let families: [WidgetFamily] = [
        .systemSmall,
        .systemMedium,
        .systemLarge,
        .systemExtraLarge,
        .accessoryInline,
        .accessoryCircular,
        .accessoryRectangular
    ]

    static var previews: some View {
        ForEach(families, id: \.self) { family in
            TodayTasksWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: family))
        }
    }
}

