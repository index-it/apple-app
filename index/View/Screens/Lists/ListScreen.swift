//
//  ListScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 04/12/24.
//

import IxCoreKit
import SwiftData
import SwiftUI
import WidgetKit

struct ListScreen: View {
    @Environment(IxNavigator.self) private var navigator
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    @Environment(\.showError) private var showError
    @Environment(\.showToast) private var showToast
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient

    private var listId: String

    // MARK: List

    @Query private var lists: [IxList]
    @State private var list: IxList = .loading()

    // MARK: Categories and selected category

    @Query private var categories: [IxListCategory]
    @AppStorage(AppStorageKeys.Categories.selectedCategory("")) private var selectedCategoryId:
        String = ""
    private var selectedCategory: IxListCategory? {
        return categories.first { $0.id == selectedCategoryId }
    }

    // MARK: Category editor

    @State private var categoryEditorConfig = EditorConfig<IxListCategory>()

    // MARK: Items

    @Query private var items: [IxListItem]
    private var completedItems: [IxListItem] {
        return items.filter { $0.completed && $0.categoryId == selectedCategory?.id }
    }

    // MARK: Selected item

    @State private var selectedItem: IxListItem? = nil
    @State private var isEditingItem = false
    @State private var showItemNotePopover = false

    // MARK: New item

    @State private var editorConfig = EditorConfig<IxListItem>()

    // MARK: Task

    @State private var taskEditorConfig = EditorConfig<IxTask>()

    // MARK: Item filters and sorting

    @AppStorage private var showCompletedItems: Bool
    @AppStorage private var itemSorting: ItemsSorting
    @AppStorage private var itemsSortOrder: SortOrder

    // MARK: Category filters and sorting

    @AppStorage private var hideUncategorized: Bool
    @AppStorage private var categoriesSorting: CategoriesSorting
    @AppStorage private var categoriesSortOrder: SortOrder

    private var contentColor: Color {
        guard let selectedCategoryColor = selectedCategory?.color else {
            return list.color.toColor()
        }

        return selectedCategoryColor.toColor()
    }

    init(listId: String) {
        self.listId = listId

        _selectedCategoryId = AppStorage(
            wrappedValue: "", AppStorageKeys.Categories.selectedCategory(listId)
        )

        // MARK: AppStorage init

        _showCompletedItems = AppStorage(
            wrappedValue: AppStorageKeys.Defaults.itemsShowCompleted,
            AppStorageKeys.Items.show_completed(listId)
        )
        _itemSorting = AppStorage(
            wrappedValue: AppStorageKeys.Defaults.itemsSorting, AppStorageKeys.Items.sorting(listId)
        )
        _itemsSortOrder = AppStorage(
            wrappedValue: AppStorageKeys.Defaults.itemsSortOrder,
            AppStorageKeys.Items.sortOrder(listId)
        )

        _hideUncategorized = AppStorage(
            wrappedValue: AppStorageKeys.Defaults.hideUncategorized,
            AppStorageKeys.Categories.hideUncategorized(listId)
        )
        _categoriesSorting = AppStorage(
            wrappedValue: AppStorageKeys.Defaults.categoriesSorting,
            AppStorageKeys.Categories.sorting(listId)
        )
        _categoriesSortOrder = AppStorage(
            wrappedValue: AppStorageKeys.Defaults.categoriesSortOrder,
            AppStorageKeys.Categories.sortOrder(listId)
        )

        // MARK: List query

        var listDescriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.id == listId
            }
        )
        listDescriptor.fetchLimit = 1
        _lists = Query(listDescriptor)

        // MARK: Categories query

        let listCategoryDescriptor = FetchDescriptor<IxListCategory>(
            predicate: #Predicate { category in
                category.listId == listId
            }
        )
        _categories = Query(listCategoryDescriptor)

        let listItemsDescriptor = FetchDescriptor<IxListItem>(
            predicate: #Predicate { item in
                item.listId == listId
            }
        )
        _items = Query(listItemsDescriptor)
    }

    // MARK: - Local storage savers

    func saveList(_ list: IxList) async throws {
        let id = list.id

        try context.transaction {
            try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
            context.insert(list)
        }

        try? await IxSystemIntegration.handleNewEntity(IxListEntity(list: list))
    }

    func saveItem(_ item: IxListItem) async throws {
        let id = item.id

        try context.transaction {
            try context.delete(model: IxListItem.self, where: #Predicate { $0.id == id })
            context.insert(item)
        }

        try? await IxSystemIntegration.handleNewEntity(IxListItemEntity(item: item))
    }

    func saveCategory(_ category: IxListCategory) async throws {
        let id = category.id

        try context.transaction {
            try context.delete(model: IxListCategory.self, where: #Predicate { $0.id == id })
            context.insert(category)
        }

        try? await IxSystemIntegration.handleNewEntity(IxListCategoryEntity(category: category))
    }

    // MARK: - Fetchers

    func fetchList() async {
        do {
            list = try await ixApiClient.getList(id: listId)
            try await saveList(list)
        } catch {
            showError(.localizedError(title: "Error loading list", error: error))
        }
    }

    func fetchCategories() async {
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

            try? await IxSystemIntegration.handleNewEntities(categories.map(IxListCategoryEntity.init))
        } catch {
            showError(.localizedError(title: "Error loading categories", error: error))
        }
    }

    func fetchItems() async {
        do {
            let items = try await ixApiClient.getListItems(listId: listId)

            try context.transaction {
                try context.delete(
                    model: IxListItem.self,
                    where: #Predicate { item in
                        item.listId == listId
                    }
                )

                for item in items {
                    context.insert(item)
                }
            }

            try? await IxSystemIntegration.handleNewEntities(items.map(IxListItemEntity.init))
        } catch {
            showError(.localizedError(title: "Error loading list items", error: error))
        }
    }

    // MARK: - Item CRUD

    func createItem() async {
        do {
            editorConfig.loading = true
            defer { editorConfig.loading = false }
            let createData = try editorConfig.sanitizeAndValidate()

            let item = try await ixApiClient.createListItem(
                listId: listId,
                categoryId: createData.categoryId,
                name: createData.name,
                link: createData.link,
                note: createData.note
            )
            try await saveItem(item)
            if editorConfig.multi {
                showToast("Item created", systemImage: "checkmark.circle", tint: .green, placement: .top)
                editorConfig.reset()
            } else {
                editorConfig.isPresented = false
            }

            Task {
                await IxSystemIntegration.donateIntent(.createItem)
            }
        } catch {
            showError(.localizedError(title: "Error creating item", error: error))
        }
    }

    func editItem() async {
        do {
            editorConfig.loading = true
            defer { editorConfig.loading = false }
            let editData = try editorConfig.sanitizeAndValidate()

            let item = try await ixApiClient.updateListItem(listId: listId, itemId: editData.id, name: editData.name, categoryId: editData.categoryId, link: editData.link, note: editData.note)
            try await saveItem(item)
            editorConfig.isPresented = false
        } catch {
            showError(.localizedError(title: "Error editing item", error: error))
        }
    }

    func categorizeItem(item: IxListItem, category: IxListCategory?) async {
        do {
            let item = try await ixApiClient.updateListItem(
                listId: item.listId,
                itemId: item.id,
                name: item.name,
                categoryId: category?.id,
                link: item.link,
                note: item.note
            )

            try await saveItem(item)

            showToast(
                category == nil ? "Uncategorized" : "Moved to \(category!.name)",
                systemImage: "tray"
            ) {
                selectedCategoryId = category?.id ?? ""
            }
        } catch {
            showError(.localizedError(title: "Error editing item", error: error))
        }
    }

    func setItemCompletion(listId: String, itemId: String, completed: Bool) async {
        do {
            let item = try await ixApiClient.setListItemCompletion(
                listId: listId, itemId: itemId, completed: completed
            )

            try await saveItem(item)
        } catch {
            showError(
                .localizedError(
                    title: "Error \(completed ? "completing" : "un-completing") item", error: error
                )
            )
        }
    }

    func setItemsCompletion(listId: String, itemIds: [String], completed: Bool) async {
        do {
            let items = try await ixApiClient.setListItemsCompletion(
                listId: listId, itemIds: itemIds, completed: completed
            )
            try context.transaction {
                try context.delete(
                    model: IxListItem.self,
                    where: #Predicate { item in
                        itemIds.contains(item.id)
                    }
                )

                for item in items {
                    context.insert(item)
                }
            }

            showToast("Uncompleted all")
        } catch {
            showError(
                .localizedError(
                    title: "Error \(completed ? "completing" : "un-completing") items", error: error
                )
            )
        }
    }

    func deleteItem(listId: String, itemId: String) async {
        do {
            try await ixApiClient.deleteListItem(listId: listId, itemId: itemId)

            try context.transaction {
                try context.delete(
                    model: IxListItem.self, where: #Predicate { item in item.id == itemId }
                )
            }

            try? await IxSystemIntegration.handleEntityDeletion(itemId, of: IxListItemEntity.self)
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(
                        model: IxListItem.self, where: #Predicate { item in item.id == itemId }
                    )
                }
            } catch {}
        } catch {
            showError(.localizedError(title: "Error deleting item", error: error))
        }
    }

    // MARK: - Category CRUD

    func createCategory() async {
        do {
            categoryEditorConfig.loading = true
            defer { categoryEditorConfig.loading = false }
            let createData = try categoryEditorConfig.sanitizeAndValidate()

            let category = try await ixApiClient.createCategory(
                listId: listId,
                name: createData.name,
                color: createData.color
            )
            try await saveCategory(category)
            categoryEditorConfig.isPresented = false
        } catch {
            showError(.localizedError(title: "Error creating category", error: error))
        }
    }

    func editCategory() async {
        do {
            categoryEditorConfig.loading = true
            defer { categoryEditorConfig.loading = false }
            let editData = try categoryEditorConfig.sanitizeAndValidate()

            let category = try await ixApiClient.updateListCategory(
                listId: listId,
                categoryId: editData.id,
                name: editData.name,
                color: editData.color
            )
            try await saveCategory(category)
            categoryEditorConfig.isPresented = false
        } catch {
            showError(.localizedError(title: "Error editing category", error: error))
        }
    }

    func deleteCategory(listId: String, categoryId: String) async {
        do {
            try await ixApiClient.deleteListCategory(listId: listId, categoryId: categoryId)

            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in category.id == categoryId }
                )
            }

            try? await IxSystemIntegration.handleEntityDeletion(categoryId, of: IxListCategoryEntity.self)
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(
                        model: IxListCategory.self,
                        where: #Predicate { category in category.id == categoryId }
                    )
                }
            } catch {}
        } catch {
            showError(.localizedError(title: "Error deleting category", error: error))
        }

        if selectedCategoryId == categoryId {
            selectedCategoryId = categories.first?.id ?? ""
        }
    }

    // MARK: Task

    func createTask() async {
        do {
            taskEditorConfig.loading = true
            defer { taskEditorConfig.loading = false }

            let createData = try taskEditorConfig.sanitizeAndValidate()
            let task = try await ixApiClient.createTask(
                name: createData.name,
                description: createData.taskDescription,
                dueDate: createData.dueDate,
                rrule: createData.rrule,
                reminders: createData.reminders,
                subtasks: createData.subtasks,
                priority: createData.priority,
                itemId: createData.itemId
            )

            try context.transaction {
                context.insert(task)
            }
            try await IxSystemIntegration.handleNewEntity(IxTaskEntity(task: task))

            taskEditorConfig.isPresented = false

            showToast("Task created", systemImage: "checkmark.circle", tint: .green, placement: .top) {
                navigator.navigateToTab(.tasks)
                navigator.taskId = task.id
            }
        } catch IxApiClientError.proRequired(_) {
            showPaywall()
        } catch {
            showError(.localizedError(title: "Error creating task", error: error))
        }
    }

    var body: some View {
        ScreenContent
            .sheet(
                isPresented: $editorConfig.isPresented,
                content: {
                    ItemEditor(
                        config: $editorConfig,
                        categories: categories,
                        onCancel: {
                            editorConfig.isPresented = false
                        }
                    ) {
                        if editorConfig.mode == .create {
                            Task {
                                await createItem()
                            }
                        } else {
                            Task {
                                await editItem()
                            }
                        }
                    }
                }
            )
            .sheet(
                isPresented: $categoryEditorConfig.isPresented,
                content: {
                    CategoryEditor(
                        config: $categoryEditorConfig,
                        onCancel: {
                            categoryEditorConfig.isPresented = false
                        }
                    ) {
                        if categoryEditorConfig.mode == .create {
                            Task {
                                await createCategory()
                            }
                        } else {
                            Task {
                                await editCategory()
                            }
                        }
                    }
                }
            )
            .sheet(isPresented: $showItemNotePopover) { [selectedItem] in
                NavigationView {
                    ScrollView(showsIndicators: false) {
                        Text(selectedItem?.note ?? "This item has no notes in it")
                    }
                    .padding()
                    .navigationTitle("\(selectedItem?.name ?? "") notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Copy", systemImage: "document.on.document") {
                                UIPasteboard.general.string = selectedItem?.note ?? ""
                            }.labelStyle(.iconOnly)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            ShareLink(item: selectedItem?.note ?? "") {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(
                isPresented: $taskEditorConfig.isPresented,
                content: {
                    TaskEditor(
                        config: $taskEditorConfig
                    ) {
                        Task {
                            await createTask()
                        }
                    }
                }
            )
            .navigationTitle(list.name)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                Task {
                    if await SyncRegister.shared.hasExpired(SyncResource.list(listId)) {
                        Task {
                            await fetchList()
                        }
                    }
                    if await SyncRegister.shared.hasExpired(SyncResource.listCategories(listId)) {
                        Task {
                            await fetchCategories()
                        }
                    }
                    if await SyncRegister.shared.hasExpired(SyncResource.listItems(listId)) {
                        Task {
                            await fetchItems()
                        }
                    }
                }
            }
            .onChange(of: navigator.categoryId, initial: true) { _, newValue in
                if let newValue {
                    selectedCategoryId = newValue
                    navigator.categoryId = nil
                }
            }
            .onChange(of: navigator.itemId, initial: true) { _, _ in
                // TODO: Decide how to highlight item
            }
            .onChange(of: lists, initial: true) { _, newLists in
                guard let newList = newLists.first else {
                    navigator.pop()
                    return
                }

                list = newList
            }
    }

    var ScreenContent: some View {
        ItemsList(
            listId: listId,
            listColor: contentColor,
            category: selectedCategory,
            categories: categories,
            showCompleted: showCompletedItems,
            sorting: itemSorting,
            sortOrder: itemsSortOrder
        ) {
            showCompletedItems = false
        } onCreateItem: {
            editorConfig.present()
        } onOpenNotes: { item in
            selectedItem = item
            showItemNotePopover = true
        } onOpenLink: { item in
            guard let link = item.link else { return }

            var urlString = link
            if !urlString.starts(with: "http") {
                urlString = "https://\(urlString)"
            }
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } onCompletionToggle: { item in
            Task {
                await setItemCompletion(
                    listId: item.listId, itemId: item.id, completed: !item.completed
                )
            }
        } onCategorize: { item, category in
            Task {
                await categorizeItem(item: item, category: category)
            }
        } onCreateCategory: {
            categoryEditorConfig.present()
        } onCreateTask: { item in
            let task = IxTask.empty()
            task.itemId = item.id
            task.name = item.name
            task.taskDescription = item.note

            taskEditorConfig.present(entity: task)
        } onEdit: { item in
            editorConfig.present(entity: item, mode: .edit)
        } onDelete: { item in
            Task {
                await deleteItem(listId: listId, itemId: item.id)
            }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(list.name)
                .foregroundStyle(contentColor.contrastColor())
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section {
                    if !completedItems.isEmpty {
                        Menu {
                            Button(
                                "Uncomplete all",
                                systemImage: "checkmark.arrow.trianglehead.counterclockwise",
                                role: .destructive
                            ) {
                                Task {
                                    await setItemsCompletion(
                                        listId: listId, itemIds: completedItems.map(\.id),
                                        completed: false
                                    )
                                }
                            }

                            Button("Cancel", role: .cancel) {}
                        } label: {
                            Label(
                                "Uncomplete all",
                                systemImage: "checkmark.arrow.trianglehead.counterclockwise"
                            )
                        }
                    }
                }

                Section {
                    Toggle(
                        "Show completed",
                        isOn: Binding(
                            get: {
                                showCompletedItems
                            },
                            set: { newValue in
                                showCompletedItems = newValue
                            }
                        )
                    )

                    Menu {
                        Picker(selection: $itemSorting) {
                            ForEach(ItemsSorting.allCases) { sorting in
                                Text(sorting.label)
                                    .tag(sorting)
                            }
                        } label: {
                            Text("Sorting")
                        }

                        //                                if itemSorting != .manual {
                        Picker(selection: $itemsSortOrder) {
                            Text(SortOrder.forward.labelForItemsSorting(itemSorting))
                                .tag(SortOrder.forward)

                            Text(SortOrder.reverse.labelForItemsSorting(itemSorting))
                                .tag(SortOrder.reverse)
                        } label: {
                            Text("Sort Order")
                        }
                        //                                }
                    } label: {
                        Button {} label: {
                            Text("Sort items by")
                            Text(categoriesSorting.label)
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }

                Section {
                    Toggle("Hide uncategorized", isOn: $hideUncategorized)

                    Menu {
                        Picker(selection: $categoriesSorting) {
                            ForEach(CategoriesSorting.allCases) { sorting in
                                Text(sorting.label)
                                    .tag(sorting)
                            }
                        } label: {
                            Text("Sorting")
                        }

                        //                                if categoriesSorting != .manual {
                        Picker(selection: $categoriesSortOrder) {
                            Text(SortOrder.forward.labelForCategoriesSorting(categoriesSorting))
                                .tag(SortOrder.forward)

                            Text(SortOrder.reverse.labelForCategoriesSorting(categoriesSorting))
                                .tag(SortOrder.reverse)
                        } label: {
                            Text("Sort Order")
                        }
                        //                                }
                    } label: {
                        Button {} label: {
                            Text("Sort categories by")
                            Text(categoriesSorting.label)
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }

            } label: {
                Label("Options", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
        }

        ToolbarItemGroup(placement: .bottomBar) {
            CategoryPicker(
                listId: listId,
                selectedCategoryId: $selectedCategoryId,
                sorting: categoriesSorting,
                sortOrder: categoriesSortOrder,
                hideUncategorized: hideUncategorized
            ) {
                categoryEditorConfig.present()
            } onEdit: { category in
                categoryEditorConfig.present(entity: category, mode: .edit)
            } onDelete: { category in
                Task {
                    await deleteCategory(listId: listId, categoryId: category.id)
                }
            }
        }

        if #available(iOS 26, *) {
            ToolbarSpacer(.fixed, placement: .bottomBar)
        }

        ToolbarItem(placement: .bottomBar) {
            Button {
                let item = IxListItem.empty()
                item.categoryId = selectedCategoryId

                editorConfig.present(
                    entity: item
                )
            } label: {
                Label("Create item", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
            .supportsLongPress {
                editorConfig.present(multi: true)
            }
        }
    }
}
