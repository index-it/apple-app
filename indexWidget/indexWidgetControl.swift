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

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description: IntentDescription = "Create a new task"
    
    func perform() async throws -> some IntentResult {
        // Construct the URL to open the app on the create task page
        guard let url = URL(string: "https://web.index-it.app/create-task") else {
            throw IxError.runtimeError("Couldn't create app intent url")
        }
        
        await OpenURLAction(handler: { url in
            return .systemAction
        }).callAsFunction(url)
        return .result()
    }
    
    static var openAppWhenRun: Bool = true
}

struct CreateListItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Create List Item"
    static var description: IntentDescription = "Create a new list item"
    
    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "https://web.index-it.app/create-item") else {
            throw IxError.runtimeError("Couldn't create app intent url")
        }
        
        await OpenURLAction(handler: { url in
            return .systemAction
        }).callAsFunction(url)
        
        return .result()
    }
    
    static var openAppWhenRun: Bool = true
}
