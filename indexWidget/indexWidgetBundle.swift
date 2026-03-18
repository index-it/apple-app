//
//  indexWidgetBundle.swift
//  indexWidget
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import WidgetKit
import AppIntents
import IxCoreKit

// if we decide to load from network instead of swiftdata
// https://developer.apple.com/documentation/widgetkit/making-network-requests-in-a-widget-extension

@main
struct indexWidgetBundle: WidgetBundle {
    init() {
        AppDependencyManager.shared.add(dependency: ModelContainerProvider.shared)
        AppDependencyManager.shared.add(dependency: IxApiClient(authChangeCallback: { _ in }))
    }
    
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
