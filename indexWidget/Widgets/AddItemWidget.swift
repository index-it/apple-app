//
//  AddItemWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import AppIntents
import IxCoreKit
import SwiftUI
import WidgetKit

struct AddItemWidget: Widget {
    let kind: String = IxKinds.openAddItemWidget
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DummyTimelineProvider()
        ) { entry in
            AddItemWidgetView()
                .widgetURL(URL(string: IxUniversalLinks.quickAdd(.item))!)
        }
        .configurationDisplayName("Add a list item")
        .description("Opens the app to add a new list item")
        .supportedFamilies([.accessoryCircular])
    }
}

struct AddItemWidgetView: View {
    var body: some View {
        ZStack {
            // https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background
            AccessoryWidgetBackground()
            
            Image(systemName: "note.text.badge.plus")
        }
    }
}
