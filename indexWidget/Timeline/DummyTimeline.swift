//
//  DummyTimeline.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import WidgetKit

struct DummyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DummyTimelineEntry {
        DummyTimelineEntry.dummy
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (DummyTimelineEntry) -> Void) {
        completion(DummyTimelineEntry.dummy)
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<DummyTimelineEntry>) -> Void) {
        completion(Timeline(entries: [DummyTimelineEntry.dummy], policy: .never))
    }
}

struct DummyTimelineEntry: TimelineEntry {
    var date: Date
    let dummy: String
    
    static let dummy = DummyTimelineEntry(date: .now, dummy: "")
}
