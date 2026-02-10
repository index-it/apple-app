//
//  ListWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

//import AppIntents
//import IxCoreKit
//import SwiftUI
//import WidgetKit
//
//struct ListWidget: Widget {
//    let kind: String = IxKinds.openAddTaskWidget
//    
//    var body: some WidgetConfiguration {
//        StaticConfiguration(
//            kind: kind,
//            provider: DummyTimelineProvider()
//        ) { entry in
//            AddTaskWidgetView()
//                .widgetURL(URL(string: IxUniversalLinks.quickAdd(.task))!)
//        }
//        .configurationDisplayName("Add a task")
//        .description("Opens the app to add a new task")
//        .supportedFamilies([.accessoryCircular])
//    }
//}
//
//struct AddTaskWidgetView: View {
//    var body: some View {
//        ZStack {
//            // https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background
//            AccessoryWidgetBackground()
//            
//            Image(systemName: "calendar.badge.plus")
//        }
//    }
//}
