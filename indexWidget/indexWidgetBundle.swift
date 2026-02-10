//
//  indexWidgetBundle.swift
//  indexWidget
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import WidgetKit

@main
struct indexWidgetBundle: WidgetBundle {
    var body: some Widget {
        AddItemWidget()
        AddTaskWidget()
        ListsWidget()
        TodayTasksWidget()
        QuickAddItemControlWidget()
        QuickAddTaskControlWidget()
    }
}
