//
//  indexWidgetBundle.swift
//  indexWidget
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import WidgetKit

// if we decide to load from network instead of swiftdata
// https://developer.apple.com/documentation/widgetkit/making-network-requests-in-a-widget-extension

@main
struct indexWidgetBundle: WidgetBundle {
    var body: some Widget {
        AddItemWidget()
        AddTaskWidget()
        ListsWidget()
        ListWidget()
        NextTaskWidget()
        TodayTasksWidget()
        TodayTasksProgressWidget()
        QuickAddItemControlWidget()
        QuickAddTaskControlWidget()
    }
}
