//
//  ItemSnippetIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData
import SwiftUI

struct ItemSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Item Snippet"

    @Parameter var item: IxListItemEntity
    @Dependency var modelContainer: ModelContainer

    init(item: IxListItemEntity) {
        self.item = item
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        return .result(
            view: ItemSnippetIntentView(item: item)
        )
    }
}

struct ItemSnippetIntentView: View {
    let item: IxListItemEntity

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(intent: CompleteItemByIdIntent(itemId: item.id, listId: item.listId)) {
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
        .padding(.top)
    }
}

#Preview {
    ItemSnippetIntentView(
        item: IxListItemEntity(item: .mock(name: "test"))
    )
    .padding()
}
