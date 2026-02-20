//
//  TasksTabView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import IxCoreKit
import EventKit
import SwiftData
import SwiftUI
import WidgetKit
import DynamicColor
import TipKit

struct TasksTabView: View {
    @Environment(IxNavigator.self) private var navigator
    @Environment(CalendarManager.self) private var calendarManager
    @Environment(\.modelContext) private var context
    @Environment(\.showPaywall) private var showPaywall
    @Environment(\.showError) private var showError
    @Environment(\.showToast) private var showToast
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient

    @AppStorage(AppStorageKeys.loggedInUser) var user: User?
    
    @State
    var tips = TipGroup(.firstAvailable) {
       TaskSwipeOrLongPressTip()
       LongPressToCreateMultipleTasksTip()
   }

    // MARK: Date

    // we take the utc date and convert it to local date using calendar with the local timezone
    @State private var todayDate: Date = DateHelper.localCalendar().startOfDay(for: Date())
    let calendar = DateHelper.localCalendar()
    
    // MARK: Calendar events
    
    @AppStorage(AppStorageKeys.Tasks.showCalendarEvents) var showCalendarEvents: Bool = AppStorageKeys.Defaults.showCalendarEvents
    @AppStorage(AppStorageKeys.Tasks.enabledCalendars) private var enabledCalendarIds = AppStorageKeys.Defaults.enabledCalendars
    @State private var calendarEvents: [EKEvent] = []
    @State private var showCalendarCreateEventSheet: IxTask? = nil

    // MARK: Task creation

    @State private var editorConfig = EditorConfig<IxTask>()

    // MARK: Selected task

    @State private var selectedTask: IxTask? = nil

    @State private var isReschedulingTask = false
    @State private var reschedulingRecurrenceState = RecurrenceState()
    @FocusState private var rescheduleDummyFocusState: Bool

    @State private var showDeleteConfirmationDialog = false
    @State private var showDeleteCompletedConfirmationDialog = false
    @State private var showClearCompletedTasksDialog = false
    
    @State private var showConvertToItemSheet: IxTask? = nil

    // MARK: Unplanned tasks

    @Query(filter: #Predicate<IxTask> { !$0.completed && $0.dueDate == nil })
    private var unplannedTasks: [IxTask]
    @AppStorage(AppStorageKeys.Tasks.unplannedTasksSectionEspanded) private var isUnplannedTasksSectionExpanded = AppStorageKeys.Defaults.unplannedTasksSectionEspanded

    // MARK: Sorting and filtering

    @AppStorage(AppStorageKeys.Tasks.sorting) private var sorting = AppStorageKeys.Defaults.tasksSorting
    @AppStorage(AppStorageKeys.Tasks.sortOrder) private var sortOrder = AppStorageKeys.Defaults.tasksSortOrder
    
    private func fetchCalendarEvents() {
        let start = todayDate
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let calendars = calendarManager.store.calendars(for: .event).filter { enabledCalendarIds.contains($0.calendarIdentifier) }
        let predicate = calendarManager.store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        calendarEvents = calendarManager.store.events(matching: predicate)
    }

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
    
    func clearCompletedTasks() async {
        do {
            try await ixApiClient.clearCompletedTasks()

            try context.transaction {
                try context.delete(model: IxTask.self, where: #Predicate { $0.completed })
            }
        } catch {
            showError(.localizedError(title: "Error clearing completed tasks", error: error))
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
    
    func setTaskPriority(
        task: IxTask,
        priority: Int?
    ) async {
        do {
            let task = try await ixApiClient.editTask(taskId: task.id, name: task.name, description: task.taskDescription, dueDate: task.dueDate, rrule: task.rrule, reminders: task.reminders, subtasks: task.subtasks, priority: priority, itemId: task.itemId)

            try await saveTask(task)
        } catch {
            showError(.localizedError(title: "Error setting task priority", error: error))
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
                    },
                    tip: tips.currentTip as? LongPressToCreateMultipleTasksTip
                )
                .overlay {
                    ZStack(alignment: .bottom) {
                        VStack {
                            Spacer()
                            TipView(tips.currentTip as? TaskSwipeOrLongPressTip)
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                                .tipBackground(.background)
                        }
                    }
                }
                .toolbar {
                    ToolbarContentView
                }
                .alert(
                    "Confirm deletion",
                    isPresented: $showDeleteConfirmationDialog
                ) {
                    if let selectedTask = selectedTask {
                        Button(selectedTask.rrule == nil ? "Delete" : "Delete This Task Only", role: .destructive) {
                            Task {
                                await deleteTask(id: selectedTask.id, all: selectedTask.rrule == nil ? nil : false)
                            }
                        }

                        if selectedTask.rrule != nil {
                            Button("Delete All Future Tasks", role: .destructive) {
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
                .sheet(
                    item: $showCalendarCreateEventSheet,
                    onDismiss: {
                        showCalendarCreateEventSheet = nil
                    }
                ) { task in
                    CalendarEventSheet(task: task, eventStore: calendarManager.store) {
                        Task {
                            await deleteTask(id: task.id)
                            showToast("Moved Task to Calendar", systemImage: "calendar.badge.checkmark")
                            fetchCalendarEvents()
                        }
                    }
                }
                .sheet(
                    item: $showConvertToItemSheet,
                    onDismiss: {
                        showConvertToItemSheet = nil
                    }
                ) { task in
                    QuickAddItemView(
                        name: task.name,
                        link: nil,
                        note: task.taskDescription,
                        selectedListId: nil,
                        selectedCategoryId: nil,
                        multi: false,
                        onFinish: { added in
                            showConvertToItemSheet = nil
                            if added {
                                Task {
                                    await deleteTask(id: task.id)
                                }
                            }
                        }
                    )
                }
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
        .onAppear {
            if calendarManager.permitted && showCalendarEvents {
                fetchCalendarEvents()
            }
        }
        .onChange(of: enabledCalendarIds) { _, _ in
            fetchCalendarEvents()
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
            fetchCalendarEvents()
        }
    }

    var TaskListView: some View {
        List {
            if !unplannedTasks.isEmpty {
                tasksListSection(
                    title: "Anyday",
                    subtitle: "\(unplannedTasks.count) unplanned tasks",
                    dateFilter: nil,
                    isToday: false,
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
                isToday: true,
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
                    isToday: false,
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
                isToday: false,
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
        isToday: Bool,
        noDateFilter: Bool,
        earlierThan: Bool,
        laterThan: Bool,
        isExpanded: Binding<Bool>? = nil,
        onHeaderTap: @escaping () -> Void
    ) -> some View {
        if let isExpanded {
            Section(isExpanded: isExpanded) {
                tasksListContent(
                    isToday: isToday,
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
                    isToday: isToday,
                    dateFilter: dateFilter,
                    noDateFilter: noDateFilter,
                    earlierThan: earlierThan,
                    laterThan: laterThan
                )
            } header: {
                VStack(alignment: .leading) {
                    tasksListSectionHeader(title: title, subtitle: subtitle, onTap: onHeaderTap)
                    
                    if let dateFilter, showCalendarEvents, calendarManager.permitted {
                        tasksListSectionCalendarEvents(date: dateFilter, isToday: isToday)
                    }
                }
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
    
    @ViewBuilder
    private func tasksListSectionCalendarEvents(
        date: Date,
        isToday: Bool,
    ) -> some View {
        let filteredEvents = calendarEvents.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
        
        if !filteredEvents.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(filteredEvents, id: \.eventIdentifier) { event in
                    HStack(alignment: .center, spacing: 0) {
//                        Circle()
//                            .fill(event.calendar.cgColor.toColor())
//                            .frame(
//                                width: UIFont.preferredFont(forTextStyle: .callout).lineHeight * 0.5,
//                                height: UIFont.preferredFont(forTextStyle: .callout).lineHeight * 0.5
//                            )
                        RoundedRectangle(cornerRadius: 2)
                            .fill(event.calendar.cgColor.toColor())
                            .frame(
                                width: 3,
                                height: UIFont.preferredFont(forTextStyle: .callout).lineHeight * 0.7
                            )
                            .padding(.trailing, 6)
                        
                        if !event.isAllDay {
                            Text(DateHelper.Formatters.calendarEventTime.string(from: event.startDate))
                                .padding(.trailing, 6)
                        }
                        
                        Text(event.title)
                    }
                    .font(.callout)
                    .foregroundStyle(DynamicColor(Color.systemLabel).lighter(amount: 0.3).toColor())
                }
            }
            .padding(.top, isToday ? 0 : 4)
            .padding(.bottom, 4)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func tasksListContent(
        isToday: Bool,
        dateFilter: Date?,
        noDateFilter: Bool,
        earlierThan: Bool,
        laterThan: Bool
    ) -> some View {
        TasksList(
            isToday: isToday,
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
        } onPrioritize: { priority, task in
            Task {
                await setTaskPriority(task: task, priority: priority)
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
        } onMoveToCalendar: { task in
            showCalendarCreateEventSheet = task
        } onConvertToItem: { task in
            showConvertToItemSheet = task
        } onOpenConnectedItem: { listId, itemId, task in
            navigator.push(.listRoute(listId: listId))
            navigator.itemId = itemId
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
                } onPrioritize: { priority, task in
                    Task {
                        await setTaskPriority(task: task, priority: priority)
                    }
                } onReschedule: { tomorrow, task in
                    if tomorrow {
                        Task {
                            await rescheduleToNextDay(task: task)
                        }
                    } else {
                        editorConfig.reset()
                        editorConfig.entity = task
                        editorConfig.mode = .edit

                        DispatchQueue.global(qos: .userInitiated).async {
                            reschedulingRecurrenceState.parseRRule(editorConfig.entity.rrule)
                        }

                        isReschedulingTask = true
                    }
                } onMoveToCalendar: { task in
                    showCalendarCreateEventSheet = task
                } onConvertToItem: { task in
                    showConvertToItemSheet = task
                } onOpenConnectedItem: { listId, itemId, task in
                    navigator.push(.listRoute(listId: listId))
                    navigator.itemId = itemId
                } onDelete: { task in
                    selectedTask = task
                    showDeleteCompletedConfirmationDialog = true
                }
                .sheet(
                    item: $showCalendarCreateEventSheet,
                    onDismiss: {
                        showCalendarCreateEventSheet = nil
                    }
                ) { task in
                    CalendarEventSheet(task: task, eventStore: calendarManager.store) {
                        Task {
                            await deleteTask(id: task.id)
                            showToast("Moved Task to Calendar", systemImage: "calendar.badge.checkmark")
                            fetchCalendarEvents()
                        }
                    }
                }
                .alert(
                    "Confirm deletion",
                    isPresented: $showDeleteCompletedConfirmationDialog
                ) {
                    if let selectedTask = selectedTask {
                        Button(selectedTask.rrule == nil ? "Delete" : "Delete This Task Only", role: .destructive) {
                            Task {
                                await deleteTask(id: selectedTask.id, all: selectedTask.rrule == nil ? nil : false)
                            }
                        }

                        if selectedTask.rrule != nil {
                            Button("Delete All Future Tasks", role: .destructive) {
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
                .alert(
                    "Clear tasks?",
                    isPresented: $showClearCompletedTasksDialog
                ) {
                    Button("Delete All Completed Tasks", role: .destructive) {
                        Task {
                            await clearCompletedTasks()
                        }
                    }

                    Button("Keep", role: .cancel) {
                        showClearCompletedTasksDialog = false
                    }
                } message: {
                    Text("Are you sure you want to delete all completed tasks? This action is irreversible!")
                }
                .navigationTitle("Completed tasks")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showClearCompletedTasksDialog = true
                        } label: {
                            Label("Clear Completed", systemImage: "windshield.front.and.wiper")
                        }
                    }
                }
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
