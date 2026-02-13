//
//  TasksTabView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import IxCoreKit
import SwiftData
import SwiftUI
import WidgetKit

struct TasksTabView: View {
    @Environment(IxNavigator.self) private var navigator
    @Environment(\.modelContext) private var context
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.showError) private var showError
    @Environment(\.showToast) private var showToast
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient

    @AppStorage(AppStorageKeys.loggedInUser) var user: User?

    // MARK: Date

    // we take the utc date and convert it to local date using calendar with the local timezone
    @State private var todayDate: Date = DateHelper.localCalendar().startOfDay(for: Date())
    let calendar = DateHelper.localCalendar()

    // MARK: Task creation

    @State private var editorConfig = EditorConfig<IxTask>()

    // MARK: Selected task

    @State private var selectedTask: IxTask? = nil

    @State private var isReschedulingTask = false
    @State private var reschedulingRecurrenceState = RecurrenceState()
    @FocusState private var rescheduleDummyFocusState: Bool

    @State private var showDeleteConfirmationDialog = false
    @State private var showDeleteCompletedConfirmationDialog = false

    // MARK: Unplanned tasks

    @Query(filter: #Predicate<IxTask> { !$0.completed && $0.dueDate == nil })
    private var unplannedTasks: [IxTask]
    @AppStorage(AppStorageKeys.Tasks.unplannedTasksSectionEspanded) private var isUnplannedTasksSectionExpanded = AppStorageKeys.Defaults.unplannedTasksSectionEspanded

    // MARK: Sorting and filtering

    @AppStorage(AppStorageKeys.Tasks.sorting) private var sorting = AppStorageKeys.Defaults.tasksSorting
    @AppStorage(AppStorageKeys.Tasks.sortOrder) private var sortOrder = AppStorageKeys.Defaults.tasksSortOrder

    private func saveTask(_ task: IxTask) async throws {
        try context.transaction {
            context.insert(task)
        }

        try? await IxSystemIntegration.handleNewEntity(IxTaskEntity(task: task))
    }

    // MARK: - Task CRUD

    func fetchTasks(completion: Bool) async {
        do {
            let tasks = try await ixApiClient.getTasks(completed: completion)

            try context.transaction {
                try context.delete(
                    model: IxTask.self,
                    where: #Predicate { task in
                        task.completed == completion
                    }
                )

                for ixTask in tasks {
                    context.insert(ixTask)
                }
            }

            try? await IxSystemIntegration.handleNewEntities(tasks.map(IxTaskEntity.init))
        } catch {
            showError(.localizedError(title: "Error loading tasks", error: error))
        }
    }

    func fetchTaskConnectedItems() async {
        do {
            let (items, categories, lists) = try await ixApiClient.getTasksConnectedItemsData()
            let itemIds = items.map { $0.id }
            let categoryIds = categories.map { $0.id }
            let listIds = lists.map { $0.id }

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

            try? await IxSystemIntegration.handleNewEntities(items.map(IxListItemEntity.init))

            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in
                        categoryIds.contains(category.id)
                    }
                )

                for category in categories {
                    context.insert(category)
                }
            }

            try? await IxSystemIntegration.handleNewEntities(categories.map(IxListCategoryEntity.init))

            try context.transaction {
                try context.delete(
                    model: IxList.self,
                    where: #Predicate { list in
                        listIds.contains(list.id)
                    }
                )

                for list in lists {
                    context.insert(list)
                }
            }

            try? await IxSystemIntegration.handleNewEntities(lists.map(IxListEntity.init))
        } catch {
            showError(.localizedError(title: "Error loading task connected items", error: error))
        }
    }

    func createTask() async {
        do {
            editorConfig.loading = true
            defer { editorConfig.loading = false }

            let createData = try editorConfig.sanitizeAndValidate()
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

            try await saveTask(task)

            if editorConfig.multi {
                showToast("Task created", systemImage: "checkmark.circle", tint: .green, placement: .top)
                editorConfig.reset()
            } else {
                editorConfig.isPresented = false
            }

            Task {
                await IxSystemIntegration.donateIntent(.createTask)
            }
        } catch IxApiClientError.proRequired(_) {
            showPaywall()
        } catch {
            showError(.localizedError(title: "Error creating task", error: error))
        }
    }

    func editTask() async {
        do {
            editorConfig.loading = true
            defer { editorConfig.loading = false }
            let editData = try editorConfig.sanitizeAndValidate()

            let task = try await ixApiClient.editTask(
                taskId: editData.id,
                name: editData.name,
                description: editData.taskDescription,
                dueDate: editData.dueDate,
                rrule: editData.rrule,
                reminders: editData.reminders,
                subtasks: editData.subtasks,
                priority: editData.priority,
                itemId: editData.itemId
            )
            try await saveTask(task)
            editorConfig.isPresented = false
        } catch {
            showError(.localizedError(title: "Error editing task", error: error))
        }
    }

    func rescheduleToNextDay(task: IxTask) async {
        do {
            let addedOneDay = task.dueDate
                .flatMap { calendar.date(byAdding: .day, value: 1, to: $0) }

            let nextDueDate = max(addedOneDay ?? Date(), Date())

            let task = try await ixApiClient.editTask(
                taskId: task.id,
                name: task.name,
                description: task.taskDescription,
                dueDate: nextDueDate,
                rrule: task.rrule,
                reminders: task.reminders,
                subtasks: task.subtasks,
                priority: task.priority,
                itemId: task.itemId
            )
            try await saveTask(task)
        } catch {
            showError(.localizedError(title: "Error rescheduling task", error: error))
        }
    }

    func setTaskCompletion(
        id: String,
        completed: Bool
    ) async {
        do {
            let task = try await ixApiClient.setTaskCompletion(taskId: id, completed: completed)

            try await saveTask(task)
        } catch {
            showError(.localizedError(title: "Error \(completed ? "completing" : "uncompleting") task", error: error))
        }
    }

    func deleteTask(id: String, all: Bool? = nil) async {
        do {
            try await ixApiClient.deleteTask(taskId: id, all: all)
            try context.transaction {
                try context.delete(model: IxTask.self, where: #Predicate { $0.id == id })
            }

            try? await IxSystemIntegration.handleEntityDeletion(id, of: IxTaskEntity.self)
        } catch IxApiClientError.notFound {
            do {
                try context.transaction {
                    try context.delete(model: IxTask.self, where: #Predicate { $0.id == id })
                }
            } catch {}
        } catch {
            showError(.localizedError(title: "Error deleting task", error: error))
        }
    }

    var body: some View {
        NavigationView {
            TaskListView
                .navigationTitle("Your tasks")
                .floatingActionButton(
                    "plus",
                    action: {
                        editorConfig.present(entity: .empty(dueDate: Date.now))
                    },
                    longPressAction: {
                        editorConfig.present(multi: true)
                    }
                )
                .toolbar {
                    ToolbarContentView
                }
                .alert(
                    "Confirm deletion",
                    isPresented: $showDeleteConfirmationDialog
                ) {
                    if let selectedTask = selectedTask {
                        Button(selectedTask.rrule == nil ? "Delete" : "Delete single", role: .destructive) {
                            Task {
                                await deleteTask(id: selectedTask.id, all: selectedTask.rrule == nil ? nil : false)
                            }
                        }

                        if selectedTask.rrule != nil {
                            Button("Delete all", role: .destructive) {
                                Task {
                                    await deleteTask(id: selectedTask.id, all: true)
                                }
                            }
                        }
                    }

                    Button("Keep", role: .cancel) {
                        showDeleteConfirmationDialog = false
                    }
                } message: {
                    Text("Are you sure you want to delete the\(selectedTask?.rrule != nil ? " recurring" : "") task \(selectedTask?.name ?? "")?")
                }
                .sheet(
                    isPresented: $editorConfig.isPresented,
                    content: {
                        TaskEditor(
                            config: $editorConfig
                        ) {
                            if editorConfig.mode == .create {
                                Task {
                                    await createTask()
                                }
                            } else {
                                Task {
                                    await editTask()
                                }
                            }
                        }
                    }
                )
                .sheet(
                    isPresented: $isReschedulingTask,
                    content: {
                        NavigationView {
                            Form {
                                TaskDateSection(
                                    config: $editorConfig,
                                    isTaskNameFocused: _rescheduleDummyFocusState,
                                    recurrenceState: reschedulingRecurrenceState
                                )
                            }
                            .navigationTitle("Date & Reminders")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button {
                                        isReschedulingTask = false
                                    } label: {
                                        Label("Cancel", systemImage: "xmark")
                                    }
                                }
                                
                                ToolbarItem(placement: .confirmationAction) {
                                    Button {
                                        Task {
                                            let rrule = reschedulingRecurrenceState.generateRRule()
                                            editorConfig.entity.rrule = rrule
                                            
                                            await editTask()
                                        }
                                        
                                        isReschedulingTask = false
                                    } label: {
                                        Label("Save", systemImage: "checkmark")
                                    }
                                }
                            }
                            .onAppear {
                                if let dueDate = editorConfig.entity.dueDate,
                                   dueDate.compare(Date.now) == .orderedAscending {
                                    editorConfig.entity.dueDate = Date.now
                                } else if editorConfig.entity.dueDate == nil {
                                    editorConfig.entity.dueDate = Date.now
                                }
                            }
                        }
                    }
                )
        }
        .onAppear {
            Task {
                let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.tasks)

                if shouldSync {
                    await fetchTasks(completion: false)
                }
            }

            Task {
                let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.tasksConnectedItems)

                if shouldSync {
                    await fetchTaskConnectedItems()
                }
            }
        }
        .onChange(of: navigator.taskCreatePresented, initial: true) { _, newValue in
            if newValue {
                editorConfig.present(multi: false)
                navigator.taskCreatePresented = false
            }
        }
        .onChange(of: navigator.taskId, initial: true) { _, _ in
            // TODO: Decide how to highlight selected task
            // we can also move this onChange to a subview like the TasksList view or smth if needed
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
            todayDate = DateHelper.localCalendar().startOfDay(for: Date.now)
        }
    }

    var TaskListView: some View {
        List {
            if !unplannedTasks.isEmpty {
                tasksListSection(
                    title: "Anyday",
                    subtitle: "\(unplannedTasks.count) unplanned tasks",
                    dateFilter: nil,
                    noDateFilter: true,
                    earlierThan: false,
                    laterThan: false,
                    isExpanded: $isUnplannedTasksSectionExpanded
                ) {
                    editorConfig.present()
                }
            }

            tasksListSection(
                title: "Today",
                dateFilter: todayDate,
                noDateFilter: false,
                earlierThan: true,
                laterThan: false
            ) {
                let task = IxTask.empty()
                task.dueDate = todayDate
                editorConfig.present(entity: task)
            }

            ForEach([1, 2, 3, 4, 5, 6], id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: todayDate)!

                tasksListSection(
                    title: offset == 1 ? "Tomorrow" : DateHelper.Formatters.taskSectionHeading.string(from: date),
                    subtitle: DateHelper.Formatters.taskSectionSubheading.string(from: date),
                    dateFilter: date,
                    noDateFilter: false,
                    earlierThan: false,
                    laterThan: false
                ) {
                    let task = IxTask.empty()
                    task.dueDate = date
                    editorConfig.present(entity: task)
                }
            }

            tasksListSection(
                title: "Later",
                dateFilter: calendar.date(byAdding: .day, value: 7, to: todayDate),
                noDateFilter: false,
                earlierThan: false,
                laterThan: true
            ) {
                let task = IxTask.empty()
                task.dueDate = calendar.date(byAdding: .day, value: 7, to: todayDate)!
                editorConfig.present(entity: task)
            }
        }
    }

    @ViewBuilder
    private func tasksListSection(
        title: String,
        subtitle: String? = nil,
        dateFilter: Date?,
        noDateFilter: Bool,
        earlierThan: Bool,
        laterThan: Bool,
        isExpanded: Binding<Bool>? = nil,
        onHeaderTap: @escaping () -> Void
    ) -> some View {
        if let isExpanded {
            Section(isExpanded: isExpanded) {
                tasksListContent(
                    dateFilter: dateFilter,
                    noDateFilter: noDateFilter,
                    earlierThan: earlierThan,
                    laterThan: laterThan
                )
            } header: {
                tasksListSectionHeader(title: title, subtitle: subtitle, onTap: onHeaderTap)
            }
        } else {
            Section {
                tasksListContent(
                    dateFilter: dateFilter,
                    noDateFilter: noDateFilter,
                    earlierThan: earlierThan,
                    laterThan: laterThan
                )
            } header: {
                tasksListSectionHeader(title: title, subtitle: subtitle, onTap: onHeaderTap)
            }
        }
    }

    private func tasksListSectionHeader(
        title: String,
        subtitle: String?,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(UIColor.label.toColor())
                .textCase(nil)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .textCase(nil)
            }
        }
        .onTapGesture(perform: onTap)
    }

    private func tasksListContent(
        dateFilter: Date?,
        noDateFilter: Bool,
        earlierThan: Bool,
        laterThan: Bool
    ) -> some View {
        TasksList(
            dateFilter: dateFilter,
            noDateFilter: noDateFilter,
            earlierThanDateFilter: earlierThan,
            laterThanDateFilter: laterThan,
            taskFilter: .uncompleted,
            taskSorting: sorting,
            sortOrder: sortOrder
        ) { task in
            editorConfig.present(entity: task, mode: .edit)
        } onCompletionToggle: { task in
            Task {
                await setTaskCompletion(id: task.id, completed: !task.completed)
            }
        } onReschedule: { task in
            editorConfig.reset()
            editorConfig.entity = task
            editorConfig.mode = .edit

            DispatchQueue.global(qos: .userInitiated).async {
                reschedulingRecurrenceState.parseRRule(editorConfig.entity.rrule)
            }

            isReschedulingTask = true
        } onRescheduleNextDay: { task in
            Task {
                await rescheduleToNextDay(task: task)
            }
        } onDelete: { task in
            selectedTask = task
            showDeleteConfirmationDialog = true
        }
    }

    @ToolbarContentBuilder
    var ToolbarContentView: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                navigator.push(.settings)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                CompletedTasksList { task in
                    editorConfig.present(entity: task, mode: .edit)
                } onCompletionToggle: { task in
                    Task {
                        await setTaskCompletion(id: task.id, completed: !task.completed)
                    }
                } onDelete: { task in
                    selectedTask = task
                    showDeleteCompletedConfirmationDialog = true
                }
                .alert(
                    "Confirm deletion",
                    isPresented: $showDeleteCompletedConfirmationDialog
                ) {
                    if let selectedTask = selectedTask {
                        Button(selectedTask.rrule == nil ? "Delete" : "Delete single", role: .destructive) {
                            Task {
                                await deleteTask(id: selectedTask.id, all: selectedTask.rrule == nil ? nil : false)
                            }
                        }

                        if selectedTask.rrule != nil {
                            Button("Delete all", role: .destructive) {
                                Task {
                                    await deleteTask(id: selectedTask.id, all: true)
                                }
                            }
                        }
                    }

                    Button("Keep", role: .cancel) {
                        showDeleteCompletedConfirmationDialog = false
                    }
                } message: {
                    Text("Are you sure you want to delete the\(selectedTask?.rrule != nil ? " recurring" : "") task \(selectedTask?.name ?? "")?")
                }
                .navigationTitle("Completed tasks")
                .onAppear {
                    Task {
                        let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.completedTasks)

                        if shouldSync {
                            await fetchTasks(completion: true)
                        }
                    }
                }
            } label: {
                Label("Completed tasks", systemImage: "book.closed")
            }
        }

        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Picker(selection: $sorting) {
                    ForEach(TasksSorting.allCases) { sorting in
                        Text(sorting.label)
                            .tag(sorting)
                    }
                } label: {
                    Text("Sorting")
                }

//                            if sorting != .manual {
                Picker(selection: $sortOrder) {
                    Text(SortOrder.forward.labelForTasksSorting(sorting))
                        .tag(SortOrder.forward)

                    Text(SortOrder.reverse.labelForTasksSorting(sorting))
                        .tag(SortOrder.reverse)
                } label: {
                    Text("Sort Order")
                }
//                            }
            } label: {
                Button {} label: {
                    Text("Sort by")
                    Text(sorting.label)
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }
}
