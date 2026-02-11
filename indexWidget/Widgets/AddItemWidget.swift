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
        ) { _ in
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
                .font(.title2)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct AddItemWidget_Previews: PreviewProvider {
    static let families: [WidgetFamily] = [
        .accessoryCircular
    ]

    static var previews: some View {
        ForEach(families, id: \.self) { family in
            AddItemWidgetView()
                .previewContext(WidgetPreviewContext(family: family))
        }
    }
}
