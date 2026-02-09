//
//  ListSnippetIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData
import SwiftUI

struct ListSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "List Snippet"

    @Parameter var list: IxListEntity
    @Dependency var modelContainer: ModelContainer

    init(list: IxListEntity) {
        self.list = list
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let listId = list.id
        let itemsDescriptor = FetchDescriptor<IxListItem>(
            predicate: #Predicate { item in item.listId == listId && !item.completed }
        )
        let items = (try? modelContainer.mainContext.fetch(itemsDescriptor)) ?? []

        let categoriesDescriptor = FetchDescriptor<IxListCategory>(
            predicate: #Predicate { category in category.listId == listId }
        )
        let categories = (try? modelContainer.mainContext.fetch(categoriesDescriptor)) ?? []

        return .result(
            view: ListSnippetIntentView(list: list, categories: categories, items: items)
        )
    }
}

struct ListSnippetIntentView: View {
    let list: IxListEntity
    let categories: [IxListCategory]
    let items: [IxListItem]

    var body: some View {
        VStack(alignment: .leading) {
            headerView

            if items.isEmpty {
                emptyView()
            } else {
                listContentView()
                    .padding(.top, 1)
            }
        }
        .padding(.top)
        .padding(.horizontal)
    }

    private var headerView: some View {
        HStack {
            Text(list.name)
                .foregroundStyle(list.color.toColor())
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Text("\(items.count)")
                .foregroundStyle(list.color.toColor())
                .font(.title2)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
        }
    }

    private func emptyView() -> some View {
        VStack {
            Spacer()
            Text("No items yet")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private func listContentView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            let nonCategorizedItems = items.filter { $0.categoryId == nil }
            if !nonCategorizedItems.isEmpty {
                itemsList(nonCategorizedItems)
            }

            ForEach(categories, id: \.id) { category in
                let filteredItems = items.filter { $0.categoryId == category.id }

                itemsList(filteredItems, of: category)
            }

            Spacer()
        }
    }

    private func itemsList(_ items: [IxListItem], of category: IxListCategory? = nil) -> some View {
        VStack(alignment: .leading) {
            if let category {
                Text(category.name)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.bottom, 3)
            }

            if items.isEmpty {
                Text("No items")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    itemRow(item)

                    if index != items.count - 1 {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
        }
    }

    private func itemRow(_ item: IxListItem) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Button(intent: CompleteItemByIdIntent(itemId: item.id, listId: list.id)) {
                    Label("Complete", systemImage: item.completed ? "inset.filled.circle" : "circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading) {
                    Text(item.name)
                        .lineLimit(1)
                        .font(.footnote)

                    if let note = item.note {
                        Text(note)
                            .lineLimit(2)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}

#Preview {
    let categories: [IxListCategory] = [.mock(name: "Category")]
    ListSnippetIntentView(
        list: IxListEntity(list: .mock(name: "Test list", emoji: "🦈", color: "#FF0000")),
        categories: categories,
        items: [.mock(name: "Buy Gocciole"), .mock(name: "Wax skis", categoryId: categories.first!.id)]
    )
    .padding()
}
