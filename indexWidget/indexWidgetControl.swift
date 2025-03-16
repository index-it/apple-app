//
//  indexWidgetControl.swift
//  indexWidget
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import AppIntents
import SwiftUI
import WidgetKit

struct CreateTaskWidgetControl: ControlWidget {
    static let kind: String = "app.index-it.index.createTaskWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(
                action: CreateTaskIntent(),
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

struct CreateListItemWidgetControl: ControlWidget {
    static let kind: String = "app.index-it.index.createListItemWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(
                action: CreateListItemIntent(),
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

