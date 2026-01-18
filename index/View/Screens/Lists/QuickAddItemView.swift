//
//  QuickAddItemView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 03/01/26.
//

import IxCoreKit
import OSLog
import SwiftData
import SwiftUI

private let log = Logger(subsystem: IxSubsystems.APP, category: "QuickAddItemView")

struct QuickAddItemView: View {
    @Environment(\.showPaywall) private var showPaywall
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var errorService: ErrorStateService

    @Binding private var itemEditorConfig = EditorConfig<IxListItem>()
    @State private var categoryEditorConfig = EditorConfig<IxListCategory>()

    @State private var loadingLinkTitle = false

    @FocusState private var isNameFieldFocused: Bool

    // MARK: List creation form vars

    @State private var isAddingList = false
    @State private var newListColor: Color = ColorHelper.randomIxColor()
    @State private var newListEmoji: String = EmojiHelper.randomEmojiForPickerInitial()

    private var onCancel: () -> Void
    private var syncThreeshold: Int64

    // MARK: Data vars

    @AppStorage(AppStorageKeys.QuickAdd.recentListId) var recentListId: String = ""

    @Query(sort: [SortDescriptor(\IxList.name)])
    private var lists: [IxList]
    @Query(sort: [SortDescriptor(\IxListCategory.name)])
    private var categories: [IxListCategory]

    init(
        itemEditorConfig: 
        name: String? = nil,
        link: String? = nil,
        note: String? = nil,
        selectedListId: String? = nil,
        selectedCategoryId: String? = nil,
        onCancel: @escaping () -> Void,
        syncThreeshold: Int64 = 3_600_000
    ) {
        itemEditorConfig.entity.name = name ?? ""
        itemEditorConfig.entity.link = link
        itemEditorConfig.entity.note = note
        self.selectedListId = selectedListId ?? ""
        self.selectedCategoryId = selectedCategoryId
        self.onCancel = onCancel
        self.syncThreeshold = syncThreeshold
    }

    private func loadLinkTitle(_ url: URL) async {
        loadingLinkTitle = true

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let html = String(data: data, encoding: .utf8) {
                if let titleRange = html.range(of: "<title>(.*?)</title>", options: .regularExpression) {
                    let titleWithTags = String(html[titleRange])
                    let title = titleWithTags
                        .replacingOccurrences(of: "<title>", with: "")
                        .replacingOccurrences(of: "</title>", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    itemEditorConfig.entity.name = title
                }
            }

            loadingLinkTitle = false
        } catch {
            log.error("Error loading link page to get title: \(error.localizedDescription)")
            loadingLinkTitle = false
        }
    }

    private func fetchLists() async {
        do {
            let lists = try await ixApiClient.getLists()

            try context.transaction {
                try context.delete(model: IxList.self)

                for ixList in lists {
                    context.insert(ixList)
                }
            }

        } catch {}
    }

    private func fetchCategories(listId: String) async {
        do {
            let categories = try await ixApiClient.getListCategories(listId: listId)

            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in
                        category.listId == listId
                    }
                )

                for category in categories {
                    context.insert(category)
                }
            }
        } catch {}
    }

    private func createList(name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.createList(name: name, icon: emoji, color: color.hexString, archived: false, is_public: isPublic)

            try context.transaction {
                context.insert(list)
            }

            selectedListId = list.id
        } catch IxApiClientError.proRequired(_) {
            showPaywall()
        } catch {
            errorService.insert(.localizedError(title: "Error creating list", error: error))
        }
    }

    func createCategory() async {
        do {
            categoryEditorConfig.loading = true
            defer { categoryEditorConfig.loading = false }
            
            let data = try categoryEditorConfig.sanitizeAndValidate()
            let category = try await ixApiClient.createCategory(listId: selectedListId, name: data.name, color: data.color)

            try context.transaction {
                context.insert(category)
            }

            selectedCategoryId = category.id
        } catch {
            errorService.insert(.localizedError(title: "Error creating category", error: error))
        }
    }

    private func save(
        listId: String,
        categoryId: String?,
        name: String,
        link: String?,
        note: String?
    ) async {
        do {
            let item = try await ixApiClient.createListItem(listId: listId, categoryId: categoryId, name: name, link: link, note: note)

            Task { @MainActor in
                do {
                    try context.transaction {
                        context.insert(item)
                    }
                } catch {}
            }

            onCancel()
        } catch {
            onCancel()
        }
    }

    var body: some View {
        QuickAddView
            .onAppear {
                if itemEditorConfig.entity.name.isEmpty && itemEditorConfig.entity.link?.isEmpty == true {
                    isNameFieldFocused = true
                }

                if let link = itemEditorConfig.entity.link, !link.isEmpty, let url = URL(string: link) {
                    Task {
                        await loadLinkTitle(url)
                    }
                }

                Task {
                    if await SyncRegister.shared.hasExpired(SyncResource.lists, threshold: syncThreeshold) {
                        await fetchLists()
                    }
                }
            }
            .onChange(of: lists, initial: true) { _, newValue in
                if selectedListId.isEmpty, let listId = (recentListId.isEmpty ? newValue.first?.id : recentListId) {
                    selectedListId = listId
                }
            }
            .onChange(of: selectedListId) { _, newValue in
                let recentCategoryId = UserDefaults.standard.string(forKey: AppStorageKeys.QuickAdd.recentCategoryId(for: newValue)) ?? ""
                selectedCategoryId = recentCategoryId.isEmpty ? nil : recentCategoryId

                Task {
                    if await SyncRegister.shared.hasExpired(SyncResource.listCategories(newValue), threshold: syncThreeshold) {
                        await fetchCategories(listId: newValue)
                    }
                }
            }
    }

    private var QuickAddView: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(loadingLinkTitle ? "Loading website title..." : "Name", text: $itemEditorConfig.entity.name, axis: .vertical)
                        .focused($isNameFieldFocused)

                    TextField("Link", text: $itemEditorConfig.entity.link ?? "", axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Notes", text: $itemEditorConfig.entity.note ?? "", axis: .vertical)
                        .lineLimit(3...)
                } header: {
                    HStack {
                        if loadingLinkTitle {
                            ProgressView()
                        }

                        Text("Item info")
                    }
                }

                Section {
                    Picker(selection: $selectedListId) {
                        ForEach(lists.sorted { $0.name < $1.name }, id: \.id) { list in
                            Text("\(list.icon)  \(list.name)")
                                .tag(list.id)
                        }
                    } label: {
                        Text("List")
                    }
                    .pickerStyle(.menu)

                    Picker(selection: $selectedCategoryId) {
                        Text("No category").tag(nil as String?)

                        ForEach(categories.filter { cat in cat.listId == selectedListId }.sorted { $0.name < $1.name }, id: \.id) { category in
                            Text(category.name).tag(category.id)
                        }
                    } label: {
                        Text("Category")
                    }
                    .pickerStyle(.menu)
                } header: {
                    HStack {
                        Text("Save in")

                        Spacer()

                        Menu {
                            Button("Create List", systemImage: "plus") {
                                isAddingList = true
                            }

                            Button("Create Category", systemImage: "plus") {
                                isAddingCategory = true
                            }
                            .disabled(selectedListId.isEmpty)
                        } label: {
                            Label("Create list or category", systemImage: "plus.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
            .navigationTitle("Index it")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAddingList) {
                ListEditor(
                    isPresented: $isAddingList,
                    addingNew: true,
                    name: "",
                    color: newListColor,
                    emoji: newListEmoji,
                    isPublic: false,
                    colors: ColorHelper.ixColors
                ) { name, color, emoji, isPublic in
                    Task {
                        await createList(name: name, color: color, emoji: emoji, isPublic: isPublic)
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(
                isPresented: $isAddingCategory,
                content: {
                    CategoryEditor(
                        config: $categoryEditorConfig,
                        onCancel: {
                            categoryEditorConfig.isPresented = false
                        }
                    ) {
                        Task {
                            await createCategory()
                        }
                    }
                }
            )

            .toolbar {
                ToolbarViewContent
            }
        }
    }

    @ToolbarContentBuilder
    private var ToolbarViewContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
                onCancel()
            }
            .labelStyle(.iconOnly)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                // update recents
                recentListId = selectedListId
                UserDefaults.standard.set(selectedCategoryId ?? "", forKey: AppStorageKeys.QuickAdd.recentCategoryId(for: selectedListId))

                // validate values
                let link = link.isEmpty ? nil : link.trimmingCharacters(in: .whitespacesAndNewlines)
                let note = note.isEmpty ? nil : note

                // perform save
                Task {
                    await save(listId: selectedListId, categoryId: selectedCategoryId, name: name, link: link, note: note)
                }
            }
            .buttonStyle(.glassProminent)
            .disabled(name.isEmpty)
        }
    }
}

#Preview {
    QuickAddItemView(
        name: nil,
        link: nil,
        note: nil,
        selectedListId: nil,
        selectedCategoryId: nil,
        onCancel: {}
    )
    .environment(\.ixApiClient, IxApiClient(authChangeCallback: { _ in
    }))
}
