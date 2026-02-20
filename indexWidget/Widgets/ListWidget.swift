//
//  ListWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import AppIntents
import IxCoreKit
import SwiftUI
import WidgetKit

struct ListWidget: Widget {
    private func calculateWidgetURL(entry: ListTimelineProvider.Entry) -> URL {
        let urlString: String
        if entry.filteredByCategory {
            urlString = IxUniversalLinks.category(listId: entry.list.id, entry.categoryFilter?.id)
        } else {
            urlString = IxUniversalLinks.list(entry.list.id)
        }
        
        return URL(string: urlString)!
    }
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: IxKinds.listWidget,
            intent: ListConfigurationWidgetIntent.self,
            provider: ListTimelineProvider()
        ) { entry in
            ListWidgetView(entry: entry)
                .widgetURL(calculateWidgetURL(entry: entry))
        }
        .configurationDisplayName("List")
        .description("Displays a List")
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .systemExtraLarge,
                .accessoryCircular,
                .accessoryInline,
                .accessoryRectangular
            ]
        )
    }
}

struct ListWidgetView: View {
    var entry: ListTimelineProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var renderingMode
    
    private var listName: String {
        entry.list.name
    }
    
    private var maxItems: Int {
        let max: Int
        switch widgetFamily {
        case .accessoryRectangular:
            max = 3
        case .systemSmall:
            max = 3
        case .systemMedium:
            max = 4
        case .systemLarge:
            max = 7

        default:
            max = 7
        }
        
        if entry.filteredByCategory {
            return max
        } else {
            let differentCategories = Set(entry.items.prefix(max).compactMap { $0.categoryId }).count
            return max - Int(ceil(Double(differentCategories) * 0.5))
        }
    }
    
    var body: some View {
        listView
            .containerBackground(.background, for: .widget)
//            .task {
//                await IxWidgetDependencies.setup()
//            }
    }
    
    @ViewBuilder
    var listView: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryInline:
            accessoryInlineView
        case .accessoryRectangular:
            accessoryRectangularView
        case .systemSmall:
            systemSmallView
        case .systemMedium:
            systemMediumView
        case .systemLarge:
            systemLargeView
        default:
            systemLargeView
        }
    }
    
    var accessoryCircularView: some View {
        ZStack {
            // https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background
            AccessoryWidgetBackground()
            
            if entry.items.isEmpty {
                Text("No\nItems")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            } else {
                VStack {
                    Text("\(entry.items.count)")
                        .fontWeight(.semibold)
                    Text("Items")
                }
            }
        }
    }
    
    var accessoryInlineView: some View {
        HStack {
            Image(systemName: "list.bullet")
            
            if entry.items.isEmpty {
                Text("No Items In \(listName)")
            } else {
                Text("\(entry.items.count) items in \(listName)")
            }
        }
    }
    
    var accessoryRectangularView: some View {
        VStack(alignment: .leading) {
            if entry.items.isEmpty {
                Text(listName)
                    .fontWeight(.bold)
                Text("No Items")
            } else {
                if entry.items.count < maxItems {
                    Text(listName)
                        .fontWeight(.bold)
                }
                
                ForEach(entry.items.prefix(maxItems), id: \.id) { item in
                    HStack(spacing: 6) {
                        Button(intent: CompleteItemByIdIntent(itemId: item.id, listId: entry.list.id)) {
                            Image(systemName: item.completed ? "inset.filled.circle" : "circle")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Text(item.name)
                            .lineLimit(1)
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth:. infinity)
    }
    
    var systemSmallView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(listName)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .if(renderingMode == .fullColor, transform: { view in
                        view.foregroundStyle(entry.list.color.toColor().contrastColor())
                    })
                    .if(renderingMode != .fullColor, transform: { view in
                        view.foregroundStyle(Color.accentColor)
                    })
                    .widgetAccentable()
                Spacer()
                Text("\(entry.items.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
                    .widgetAccentable()
            }
            
            if entry.items.isEmpty {
                Text("No Items")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                listContentView()
            }
            
            Spacer()
        }
    }
    
    var systemMediumView: some View {
        HStack {
            VStack {
                createItemButtonView
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("\(entry.items.count)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .widgetAccentable()
                    Text(listName)
                        .fontWeight(.semibold)
                        .if(renderingMode == .fullColor, transform: { view in
                            view.foregroundStyle(entry.list.color.toColor().contrastColor())
                        })
                        .if(renderingMode != .fullColor, transform: { view in
                            view.foregroundStyle(Color.accentColor)
                        })
                        .widgetAccentable()
                }
            }
            
            if entry.items.isEmpty {
                HStack {
                    Spacer()
                    Text("No Items")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                listContentView()
            }
        }
    }
    
    var systemLargeView: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.items.count)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .widgetAccentable()
                    Text(listName)
                        .fontWeight(.semibold)
                        .if(renderingMode == .fullColor, transform: { view in
                            view.foregroundStyle(entry.list.color.toColor().contrastColor())
                        })
                        .if(renderingMode != .fullColor, transform: { view in
                            view.foregroundStyle(Color.accentColor)
                        })
                        .widgetAccentable()
                }
                
                Spacer()
                
                createItemButtonView
            }
            
            Divider()
            
            if entry.items.isEmpty {
                VStack {
                    Spacer()
                    Text("No Items")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else {
                Spacer(minLength: 10)
                
                VStack(alignment: .leading) {
                    listContentView()
                    
                    Spacer()
                }
            }
        }
    }
    
    var createItemButtonView: some View {
        Button(intent: OpenListIntent(target: IxListEntity(list: entry.list))) {
            Label("Create", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
    }
    
    private func listContentView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let itemsConsideringMax = entry.items.prefix(maxItems)
            let nonCategorizedItems = itemsConsideringMax.filter { $0.categoryId == nil }
            // we don't need to check if it has been filtered with category, because the items are already filtered by category
            if !nonCategorizedItems.isEmpty {
                itemsList(nonCategorizedItems)
            }
            
            ForEach(entry.categories, id: \.id) { category in
                let filteredItems = itemsConsideringMax.filter { $0.categoryId == category.id }
                
                if !filteredItems.isEmpty {
                    itemsList(filteredItems, of: category)
                }
            }
            
            Spacer()
        }
    }

    private func itemsList(_ items: [IxListItem], of category: IxListCategory? = nil) -> some View {
        VStack(alignment: .leading) {
            if let category {
                Text(category.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            if items.isEmpty {
                Text("No items")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Button(intent: CompleteItemByIdIntent(itemId: item.id, listId: entry.list.id)) {
                            Label("Complete", systemImage: item.completed ? "inset.filled.circle" : "circle")
                                .labelStyle(.iconOnly)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }.buttonStyle(.plain)
                        
                        Text(item.name)
                            .lineLimit(1)
                            .font(.footnote)
                            .padding(.top, -1)
                            .padding(.bottom, -1)
                        
                        Spacer()
                    }

                    if index != items.count - 1 {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
        }
    }
}


struct ListWidget_Previews: PreviewProvider {
    static let entry = ListEntry(
        date: .now,
        list: .mock(name: "Preview", emoji: "🔬", color: "#00FF00"),
        filteredByCategory: false,
        categoryFilter: nil,
        categories: [
            .mock(name: "Test category"),
            .mock(name: "Another cat")
        ],
        items: [
            .mock(name: "First item"),
            .mock(name: "Second item"),
            .mock(name: "Third item"),
        ]
    )

    static let families: [WidgetFamily] = [
        .systemSmall,
        .systemMedium,
        .systemLarge,
        .systemExtraLarge,
        .accessoryInline,
        .accessoryCircular,
        .accessoryRectangular
    ]

    static var previews: some View {
        ForEach(families, id: \.self) { family in
            ListWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: family))
        }
    }
}
