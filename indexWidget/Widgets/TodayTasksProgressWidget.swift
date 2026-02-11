//
//  TodayTasksProgress.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData
import SwiftUI
import WidgetKit

struct TodayTasksProgressWidget: Widget {
    let kind: String = IxKinds.todayTasksProgressWidget
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: TodayTasksProgressTimelineProvider()
        ) { entry in
            TodayTasksProgressWidgetView(entry: entry)
                .widgetURL(URL(string: IxUniversalLinks.tasks)!)
        }
        .configurationDisplayName("Tasks Progress")
        .description("Displays a configurable progress view for your tasks.")
        .supportedFamilies([.accessoryCircular])
    }
}



struct TodayTasksProgressWidgetView: View {
    var entry: TodayTasksProgressTimelineProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    
    private var progressValue: Double {
        entry.total == 0 ? 1 : Double(entry.completed) / Double(entry.total)
    }
    
    var body: some View {
        tasksView
            .containerBackground(.background, for: .widget)
            .task {
                await IxWidgetDependencies.setup()
            }
    }
    
    @ViewBuilder
    var tasksView: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        default:
            accessoryCircularView
        }
    }
    
    var accessoryCircularView: some View {
        ProgressView(value: progressValue) {
            Image(systemName: "figure.mind.and.body")
                .font(.title3)
        }.progressViewStyle(.circular)
    }
}

struct TodayTasksProgressWidgetView_Previews: PreviewProvider {
    static let entry = TodayTasksProgressTimelineProvider.Entry(
        date: .now,
        total: 6,
        completed: 5
    )

    static let families: [WidgetFamily] = [
        .accessoryCircular
    ]

    static var previews: some View {
        ForEach(families, id: \.self) { family in
            TodayTasksProgressWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: family))
        }
    }
}
