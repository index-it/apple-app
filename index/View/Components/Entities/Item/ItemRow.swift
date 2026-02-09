//
//  ItemRow.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import DynamicColor
import IxCoreKit
import SwiftUI

struct ItemRow: View {
    @Environment(\.showToast) private var showToast
    @Environment(\.colorScheme) var colorScheme
    var item: IxListItem
    var categories: [IxListCategory]

    var onOpenNotes: (IxListItem) -> Void
    var onOpenLink: (IxListItem) -> Void
    var onCompletionToggle: (IxListItem) -> Void
    var onCategorize: (IxListItem, IxListCategory?) -> Void
    var onCreateCategory: () -> Void
    var onCreateTask: (IxListItem) -> Void
    var onEdit: (IxListItem) -> Void
    var onDelete: (IxListItem) -> Void

    private var url: URL? {
        guard let link = item.link else { return nil }
        return URL(string: link)
    }

    private var note: String? {
        guard let note = item.note else { return nil }
        return note.isEmpty ? nil : note
    }

    private var link: String? {
        guard let link = item.link else { return nil }
        return link.isEmpty ? nil : link
    }

    var body: some View {
        HStack(spacing: 12) {
            if item.completed {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: note != nil ? 2 : 9) {
                HStack {
                    Menu {
                        MenuContentView()
                    } label: {
                        Text(item.name)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color.systemLabel)

                        Spacer()
                    }

                    if note != nil {
                        Button("See note", systemImage: "note.text") {
                            onOpenNotes(item)
                        }
                        .labelStyle(.iconOnly)
                        .padding(.horizontal)
                        .font(.title3)
//                        Button {
//                            onOpenNotes(item)
//                        } label: {
//                            Label("See note", systemImage: "text.alignleft")
//                                .foregroundStyle(Color.systemLabel)
//                                .padding(2)
//                        }
//                        .labelStyle(.iconOnly)
//                        .buttonBorderShape(.circle)
//                        .buttonStyle(.bordered)
                    }
                }

                if let link = link {
                    LinkButtonView(link: link, url: url) {
                        onOpenLink(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func MenuContentView() -> some View {
        if item.note != nil || item.link != nil {
            ControlGroup {
                if note != nil {
                    Button("Open note", systemImage: "note.text") {
                        onOpenNotes(item)
                    }
                }

                if link != nil {
                    Button("Open link", systemImage: "link") {
                        onOpenLink(item)
                    }
                }
            }
        }

        Section {
            if note == nil && link == nil {
                Button("Copy", systemImage: "document.on.document") {
                    UIPasteboard.general.string = item.name
                    showToast("Item copied", systemImage: "document.on.document")
                }
            } else {
                Menu {
                    Button("Name", systemImage: "textformat") {
                        UIPasteboard.general.string = item.name
                        showToast("Item copied", systemImage: "document.on.document")
                    }

                    if let note = item.note {
                        Button("Note", systemImage: "note.text") {
                            UIPasteboard.general.string = note
                            showToast("Note copied", systemImage: "document.on.document")
                        }
                    }

                    if let link = item.link {
                        Button("Link", systemImage: "link") {
                            if let url = url {
                                UIPasteboard.general.url = url
                            } else {
                                UIPasteboard.general.string = link
                            }

                            showToast("Link copied", systemImage: "document.on.document")
                        }
                    }
                } label: {
                    Label("Copy", systemImage: "document.on.document")
                }
            }

            if note == nil && link == nil {
                ShareLink(item: item.name) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } else {
                Menu {
                    ShareLink(item: item.name) {
                        Label("Name", systemImage: "textformat")
                    }

                    if let note = item.note {
                        ShareLink(item: note) {
                            Label("Note", systemImage: "note.text")
                        }
                    }

                    if let link = item.link {
                        ShareLink(item: link) {
                            Label("Link", systemImage: "link")
                        }
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }

        Section {
            Menu {
                ForEach(categories) { category in
                    Button {
                        if item.categoryId != category.id {
                            onCategorize(item, category)
                        }
                    } label: {
                        HStack {
                            if item.categoryId == category.id {
                                Image(systemName: "checkmark")
                            }

                            Text(category.name)
                        }
                    }
                }

                Button {
                    onCategorize(item, nil)
                } label: {
                    HStack {
                        if item.categoryId == nil {
                            Image(systemName: "checkmark")
                        }

                        Text("Uncategorized")
                    }
                }

                Section {
                    Button("Create category", systemImage: "plus") {
                        onCreateCategory()
                    }
                }
            } label: {
                Label("Categorize", systemImage: "tray")
            }

            Button("Create task", systemImage: "rectangle.grid.1x2") {
                onCreateTask(item)
            }
        }

        Section {
            Button("Edit", systemImage: "pencil") {
                onEdit(item)
            }

            Menu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete(item)
                }

                Button("Cancel", role: .cancel) {}
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    //    var body: some View {
//        HStack {
//            Menu {
//                ControlGroup {
//                    if item.note != nil && !item.note!.isEmpty {
//                        Button("See notes", systemImage: "text.page") {
//                            onOpenNotes(item)
//                        }
//                    }
//
//                    if item.link != nil {
//                        Button("Open link", systemImage: "link") {
//                            onOpenLink(item)
//                        }
//                    }
//                }
//
//                Button(item.completed ? "Uncomplete" : "Complete", systemImage: item.completed ? "xmark" : "checkmark") {
//                    onCompletionToggle(item)
//                }
//
//
//                Button("Create task", systemImage: "rectangle.grid.1x2.fill") {
//                    onCreateTask(item)
//                }
//
//                Section {
//                    Button("Edit", systemImage: "pencil") {
//                        onEdit(item)
//                    }
//
//                    Menu {
//                        Button("Delete", systemImage: "trash", role: .destructive) {
//                            onDelete(item)
//                        }
//
//                        Button("Cancel", role: .cancel) {}
//                    } label: {
//                        Label("Delete", systemImage: "trash")
//                    }
//                }
//            } label: {
//                ItemRowContent
//            }
//
//            HStack(spacing: 8) {
//                if item.note != nil {
//                    Button {
//                        onOpenNotes(item)
//                    } label: {
//                        Label("See notes", systemImage: "text.page")
//                            .labelStyle(.iconOnly)
//                            .padding(6)
//                            .foregroundStyle(color?.contrastColor() ?? Color.accentColor)
//                    }.background(Color.clear)
//                }
//
//                if item.link != nil {
//                    Button {
//                        onOpenLink(item)
//                    } label: {
//                        Label("Open link", systemImage: "link")
//                            .labelStyle(.iconOnly)
//                            .padding(6)
//                            .foregroundStyle(color?.contrastColor() ?? Color.accentColor)
//                    }.background(Color.clear)
//                }
//            }.frame(alignment: .trailing)
//        }
    ////        .listRowBackground(color)
//    }
//
//    // MARK: Item card
//    var ItemRowContent: some View {
//        HStack {
//            if item.completed {
//                Image(systemName: "checkmark")
//                    .fontWeight(.semibold)
//            }
//
//            Text(item.name)
//                .multilineTextAlignment(.leading)
//
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .foregroundStyle(UIColor.label.toColor())
//    }
}

#Preview {
    List {
        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item very long nam",
                completed: true,
                link: "https://tradeinn.com",
                note: "Hi",
                created_at: 0,
                edited_at: 0,
                completed_at: nil
            ),
            categories: [],
            onOpenNotes: { _ in },
            onOpenLink: { _ in },
            onCompletionToggle: { _ in },
            onCategorize: { _, _ in },
            onCreateCategory: {},
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )

        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: false,
                link: nil,
                note: "hello",
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            categories: [],
            onOpenNotes: { _ in },
            onOpenLink: { _ in },
            onCompletionToggle: { _ in },
            onCategorize: { _, _ in },
            onCreateCategory: {},
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )

        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Love Kotlin",
                completed: true,
                link: "kotlin.org",
                note: "Kotlin is an amazing language!",
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            categories: [],
            onOpenNotes: { _ in },
            onOpenLink: { _ in },
            onCompletionToggle: { _ in },
            onCategorize: { _, _ in },
            onCreateCategory: {},
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )

        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Test item",
                completed: true,
                link: nil,
                note: nil,
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            categories: [],
            onOpenNotes: { _ in },
            onOpenLink: { _ in },
            onCompletionToggle: { _ in },
            onCategorize: { _, _ in },
            onCreateCategory: {},
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )

        ItemRow(
            item: IxListItem(
                id: UUID().uuidString,
                user_id: "",
                list_id: "",
                category_id: nil,
                name: "Anotehr item",
                completed: true,
                link: "https://swift.org",
                note: nil,
                created_at: 0,
                edited_at: 0,
                completed_at: 0
            ),
            categories: [],
            onOpenNotes: { _ in },
            onOpenLink: { _ in },
            onCompletionToggle: { _ in },
            onCategorize: { _, _ in },
            onCreateCategory: {},
            onCreateTask: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
    }
    .scrollContentBackground(.hidden)
    .background(Color.blue.secondary)
}
