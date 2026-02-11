//
//  ListTimeline.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import WidgetKit
import IxCoreKit
import SwiftData
import OSLog

struct ListEntry: TimelineEntry {
    let date: Date
    let list: IxList
    
    let filteredByCategory: Bool
    let categoryFilter: IxListCategory?
    let categories: [IxListCategory]
    let items: [IxListItem]
}

struct ListTimelineProvider: AppIntentTimelineProvider {
    
    
    /// Used when the widget is loading
    func placeholder(in _: Context) -> ListEntry {
        ListEntry(
            date: .now,
            list: IxList.mock(name: "Loading...", emoji: "🔄", color: IxColorEnum.darkGreen.color.hexString),
            filteredByCategory: false,
            categoryFilter: nil,
            categories: [],
            items: []
        )
    }
    
    /// Used by widget previews when the user scrolls the available widgets
    func snapshot(for configuration: ListConfigurationWidgetIntent, in context: Context) async -> ListEntry {
        ListEntry(
            date: .now,
            list: IxList.mock(name: "Sailing destinations", emoji: "⛵", color: IxColorEnum.lightBlue.color.hexString),
            filteredByCategory: false,
            categoryFilter: nil,
            categories: [],
            items: [
                .mock(name: "Lastovo Archipelago, Croatia"),
                .mock(name: "San Blas Islands, Panama"),
                .mock(name: "Lofoten Islands, Norway")
            ]
        )
    }
    
    func timeline(for configuration: ListConfigurationWidgetIntent, in context: Context) async -> Timeline<ListEntry> {
        let task = Task { @MainActor in
            do {
                guard let listId = configuration.list?.id else { throw IxIntentError.unknown }
                let modelContext = ModelContext(ModelContainerProvider.shared)
                let descriptor = FetchDescriptor<IxList>(predicate: #Predicate { $0.id == listId })
                
                guard let list: IxList = try modelContext.fetch(descriptor).first else { throw IxIntentError.unknown }
                let categories = try modelContext.fetch(FetchDescriptor<IxListCategory>(predicate: #Predicate { $0.listId == listId }))
                let categoryId = configuration.category?.id
                let categoryFilter = configuration.filterByCategory ? categories.first { $0.id == categoryId } : nil
                let itemsDescriptor: FetchDescriptor<IxListItem>
                if configuration.filterByCategory {
                    itemsDescriptor = FetchDescriptor<IxListItem>(predicate: #Predicate {
                        $0.listId == listId && !$0.completed && $0.categoryId == categoryId
                    })
                } else {
                    itemsDescriptor = FetchDescriptor<IxListItem>(predicate: #Predicate {
                        $0.listId == listId && !$0.completed
                    })
                }
                let items = try modelContext.fetch(itemsDescriptor)
                
                let entry = ListEntry(date: .now, list: list, filteredByCategory: configuration.filterByCategory, categoryFilter: categoryFilter, categories: categories, items: items)
                
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date.now)!
                return Timeline(entries: [entry], policy: .after(nextUpdate))
            } catch {
                Logger.intentLogger.error("Failed creating list timeline: \(error)")
                return Timeline(
                    entries: [ListEntry(date: .now, list: .mock(name: "List Not Found", emoji: "🔍", color: "#000000"), filteredByCategory: false, categoryFilter: nil, categories: [], items: [])],
                    policy: .never
                )
            }
        }
        
        return await task.value
    }
}
