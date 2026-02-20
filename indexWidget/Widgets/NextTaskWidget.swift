//
//  NextTaskWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData
import SwiftUI
import WidgetKit

struct NextTaskWidget: Widget {
    let kind: String = IxKinds.nextTaskWidget
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: NextTaskConfigurationWidgetIntent.self,
            provider: NextTaskTimelineProvider()
        ) { entry in
            NextTaskWidgetView(entry: entry)
                .widgetURL(URL(string: IxUniversalLinks.tasks)!)
        }
        .configurationDisplayName("Next Task")
        .description("Smartly display your next task")
        .supportedFamilies(
            [
                .accessoryInline,
                .accessoryRectangular
            ]
        )
    }
}



struct NextTaskWidgetView: View {
    var entry: NextTaskTimelineProvider.Entry
    
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
        case .accessoryInline:
            accessoryInlineView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            accessoryRectangularView
        }
    }
    
    var accessoryInlineView: some View {
        HStack {
            Image(systemName: entry.task != nil ? "calendar" : "figure.mind.and.body")
            
            Text(entry.task?.name ?? "No Tasks")
        }
    }
    
    var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Next Up")
                .fontWeight(.bold)
                .widgetAccentable()
            if let task = entry.task {
                HStack {
                    Button(intent: CompleteTaskByIdIntent(taskId: task.id)) {
                        Label("Complete", systemImage: task.completed ? "inset.filled.circle" : "circle")
                            .labelStyle(.iconOnly)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                    
                    Text(task.name)
                        .lineLimit(1)
                    
                    Spacer()
                }
            } else {
                Text("No Tasks")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
