//
//  ListsTimeline.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import IxCoreKit
import WidgetKit
import SwiftData

struct ListsEntry: TimelineEntry {
    let date: Date
    let lists: [IxList]
}

struct ListsTimelineProvider: TimelineProvider {
    /// Used when the widget is loading
    func placeholder(in _: Context) -> ListsEntry {
        ListsEntry(date: .now, lists: [])
    }
    
    /// Used by widget previews when the user scrolls the available widgets
    func getSnapshot(in _: Context, completion: @escaping (ListsEntry) -> Void) {
        let entry = ListsEntry(
            date: Date.now,
            lists: [
                IxList.mock(name: "Ideas", emoji: "💡", color: IxColorEnum.darkGreen.color.hexString),
                IxList.mock(name: "Articles to read", emoji: "📚", color: IxColorEnum.orange.color.hexString),
                IxList.mock(name: "Sailing destinations", emoji: "⛵", color: IxColorEnum.lightBlue.color.hexString)
            ]
        )
        completion(entry)
    }
    
    func getTimeline(in _: Context, completion: @escaping (Timeline<ListsEntry>) -> Void) {
        Task { @MainActor in
            var lists: [IxList] = []
            let modelContext = ModelContext(ModelContainerProvider.shared)
            let descriptor = FetchDescriptor<IxList>(predicate: #Predicate { !$0.archived }, sortBy: [SortDescriptor(\IxList.name)])
            
            do {
                lists = try modelContext.fetch(descriptor)
            } catch {
                print("Failed to fetch tasks: \(error)")
            }
            
            let entry = ListsEntry(
                date: Date.now,
                lists: lists
            )
            
            // Update every hour or when the widget refreshes
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date.now)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}
