//
//  indexWidgetControl.swift
//  indexWidget
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import AppIntents
import SwiftUI
import WidgetKit
import IxCoreKit

struct QuickAddTaskControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: IxKinds.quickAddTaskControlCenterWidget
        ) {
            ControlWidgetButton(
                action: QuickAddTaskIntent(),
                label: {
                    VStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Create Task")
                    }
                }
            )
        }
        .displayName("Create Task")
        .description("Quickly create a new task.")
    }
}

struct QuickAddItemControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: IxKinds.quickAddItemControlCenterWidget
        ) {
            ControlWidgetButton(
                action: QuickAddItemIntent(),
                label: {
                    VStack {
                        Image(systemName: "note.text.badge.plus")
                        Text("Index It")
                    }
                }
            )
        }
        .displayName("Index It")
        .description("Quickly add a new item to a list.")
    }
}

