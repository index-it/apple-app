//
//  OpenListsWidget.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import AppIntents
import IxCoreKit
import SwiftUI
import WidgetKit
import DynamicColor

struct ListsWidget: Widget {
    let kind: String = IxKinds.listsWidget
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ListsTimelineProvider()
        ) { entry in
            ListsWidgetView(entry: entry)
                .widgetURL(URL(string: IxUniversalLinks.lists)!)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Your Lists")
        .description("View your lists")
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .systemExtraLarge,
                .accessoryCircular
            ]
        )
    }
}

struct ListsWidgetView: View {
    var entry: ListsTimelineProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        tasksView
            .containerBackground(.background, for: .widget)
            .task {
                await IxWidgetDependencies.setup()
            }
    }
    
    @ViewBuilder
    var tasksView: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        case .systemSmall:
            listsView(cols: 1, rows: 2)
        case .systemMedium:
            listsView(cols: 2, rows: 2)
        case .systemLarge:
            listsView(cols: 2, rows: 4)
        case .systemExtraLarge:
            listsView(cols: 4, rows: 4)
        default:
            listsView(cols: 1, rows: 2)
        }
    }
    
    var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            if entry.lists.isEmpty {
                Text("No\nLists")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            } else {
                VStack {
                    Text("\(entry.lists.count)")
                        .fontWeight(.semibold)
                    Text("Lists")
                }
            }
        }
    }
    
    @ViewBuilder
    func listsView(cols: Int, rows: Int) -> some View {
        if entry.lists.isEmpty {
            Text("No Lists")
                .foregroundStyle(.secondary)
        } else {
            let lists = entry.lists.prefix(4)
            let spacing: CGFloat = 8

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let listWidth = (width - (spacing * (CGFloat(cols) - 1))) / CGFloat(cols)
                let listHeight = (height - (spacing * (CGFloat(rows) - 1))) / CGFloat(rows)
                
                Grid {
                    ForEach(Array(stride(from: 0, to: lists.count, by: cols)), id: \.self) { rowStart in
                        GridRow {
                            ForEach(0..<cols, id: \.self) { offset in
                                let index = rowStart + offset
                                if index < lists.count {
                                    listView(lists[index])
                                        .frame(width: listWidth, height: listHeight)
                                }
                            }
                        }
                    }
                }
            }
            .padding([.all], spacing)
        }
    }
    
    func listView(_ list: IxList) -> some View {
//         Link(destination: URL(string: IxUniversalLinks.list(list.id))!) {
        Button(intent: OpenListIntent(target: IxListEntity(list: list))) {
            VStack(alignment: .leading, spacing: 0) {
                if renderingMode != .fullColor,
                   let imageData = EmojiHelper.emojiImageData(list.icon),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .widgetAccentedRenderingMode(.fullColor)
                        .scaledToFit()
                        .frame(height: 24)
                        .padding(.vertical, -6)
                } else {
                    Text(list.icon)
                        .padding(.vertical, -6)
                }
                
                Spacer()
                
                Text(list.name)
                    .lineLimit(1)
                    .padding(.vertical, -6)
                    .fontWeight(.semibold)
                    .if(renderingMode == .fullColor, transform: { view in
                        view.foregroundStyle(list.color.toColor().contrastColor())
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .if(renderingMode == .fullColor) { view in
                view.background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DynamicColor(hexString: list.color).lighter(amount: 0.07).toColor(),
                                    DynamicColor(hexString: list.color).darkened(amount: 0.03).toColor()
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .if(renderingMode != .fullColor) { view in
                view.background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.accentColor.opacity(0.2))
                )
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ListsWidget_Previews: PreviewProvider {

    static let lists: [IxList] = [
        IxList.mock(name: "Sailing trips", emoji: "⛵", color: IxColorEnum.lightBlue.color.hexString),
        IxList.mock(name: "Ideas", emoji: "📝", color: IxColorEnum.orange.color.hexString)
    ]

    static let entry = ListsEntry(
        date: .now,
        lists: lists
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
            ListsWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: family))
        }
    }
}
