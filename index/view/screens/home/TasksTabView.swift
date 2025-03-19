//
//  TasksHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TasksTabView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.modelContext) private var context
    
    @AppStorage("user") var user: User?
    
    // MARK: Date
    @State private var todayDate: Date = Date.now.toLocalDate()
    
    // MARK: Task creation
    @State private var taskCreationDueDate: Date? = nil
    @State private var taskCreationNamePlaceholder = "Task name"
    
    // MARK: Selected task
    @State private var selectedTask: IxTask? = nil
    @State private var showEditSheet = false
    @State private var showDeleteConfirmationDialog = false
    
    // MARK: Sorting and filtering
    @AppStorage(AppStorageKeys.task_sorting) private var sorting: TaskSorting = AppStorageKeys.Defaults.task_sorting
    @AppStorage(AppStorageKeys.task_reverse_sorting) private var reverseSorting = AppStorageKeys.Defaults.task_reverse_sorting
    @AppStorage(AppStorageKeys.task_filter) private var filter: TaskFilter = .uncompleted
    
    private func saveTask(_ task: IxTask) async throws {
        try context.transaction {
            context.insert(task)
        }
    }
    
    // MARK: - Suggestions
    func fetchTaskTemplateSuggestion() async {
        do {
            let template = try await ixApiClient.getTaskTemplateSuggestion()
            
            taskCreationNamePlaceholder = template.name
        } catch {}
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
                
                tasks.forEach { ixTask in
                    context.insert(ixTask)
                }
            }
        } catch {
            errorService.insert(.localizedError(title: "Error loading tasks", error: error))
        }
    }
    
    func createTask(
        name: String,
        description: String?,
        dueDate: Date?,
        rrule: String?,
        reminders: [IxTaskReminder],
        subtasks: [IxSubTask],
        priority: Int?,
        itemId: String?
    ) async {
        do {
            let task = try await ixApiClient.createTask(name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
            
            try await saveTask(task)
            
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        } catch IxApiClientError.ProRequired(let proFeature) {
            // TODO: Show pro sheet with a global toggle
        } catch {
            errorService.insert(.localizedError(title: "Error creating task", error: error))
        }
    }
    
    func editTask(
        id: String,
        name: String,
        description: String?,
        dueDate: Date?,
        rrule: String?,
        reminders: [IxTaskReminder],
        subtasks: [IxSubTask],
        priority: Int?,
        itemId: String?
    ) async {
        do {
            let task = try await ixApiClient.editTask(taskId: id, name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
            
            try await saveTask(task)
            
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        } catch {
            errorService.insert(.localizedError(title: "Error editing task", error: error))
        }
    }
    
    func setTaskCompletion(
        id: String,
        completed: Bool
    ) async {
        do {
            let task = try await ixApiClient.setTaskCompletion(taskId: id, completed: completed)
            
            try await saveTask(task)
            
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        } catch {
            errorService.insert(.localizedError(title: "Error \(completed ? "completing" : "uncompleting") task", error: error))
        }
    }
    
    
    func deleteTask(id: String, all: Bool? = nil) async {
        do {
            try await ixApiClient.deleteTask(taskId: id, all: all)
            try context.transaction {
                try context.delete(model: IxTask.self, where: #Predicate { $0.id == id })
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        } catch IxApiClientError.NotFound {
            do {
                try context.transaction {
                    try context.delete(model: IxTask.self, where: #Predicate { $0.id == id })
                }
            } catch {}
        } catch {
            errorService.insert(.localizedError(title: "Error deleting task", error: error))
        }
    }
    
    var body: some View {
        NavigationView {
            TaskListView
                .navigationTitle("Your tasks")
                .floatingActionButton("plus", action: {
                    navigationManager.showCreateTaskSheet = true
                })
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            CompletedTasksList { task in
                                selectedTask = task
                                showEditSheet = true
                            } onCompletionToggle: { task in
                                Task {
                                    await setTaskCompletion(id: task.id, completed: !task.completed)
                                }
                            } onDelete: { task in
                                selectedTask = task
                                showDeleteConfirmationDialog = true
                            }
                            .navigationTitle("Completed tasks")
                            .onAppear {
                                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.COMPLETED_TASKS)
                                
                                if shouldSync {
                                    Task {
                                        await fetchTasks(completion: true)
                                    }
                                }
                            }
                        } label: {
                            Label("Completed tasks", systemImage: "book.closed")
                        }
                    }
                    
                    ToolbarItem(placement: .secondaryAction) {
                        Picker(selection: $sorting) {
                            ForEach(TaskSorting.allCases) { filter in
                                Text(filter.rawValue)
                                    .tag(filter)
                            }
                        } label: {
                            Label("Sorting", systemImage: "arrow.up.arrow.down")
                        }.pickerStyle(.menu)
                    }
                    
                    ToolbarItem(placement: .secondaryAction) {
                        Toggle("Reverse", isOn: $reverseSorting)
                    }
                }
                .confirmationDialog(
                    Text("Confirm deletion"),
                    isPresented: $showDeleteConfirmationDialog,
                    titleVisibility: .visible,
                    actions: {
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
                    },
                    message: {
                        Text("Are you sure you want to delete the\(selectedTask?.rrule != nil ? " recurring" : "") task \(selectedTask?.name ?? "")?")
                    }
                )
                .sheet(
                    isPresented: $navigationManager.showCreateTaskSheet,
                    content: { [taskCreationDueDate] in
                        TaskFormSheet(
                            showSheet: $navigationManager.showCreateTaskSheet,
                            name: "",
                            description: nil,
                            priority: nil,
                            dueDate: taskCreationDueDate,
                            rrule: nil,
                            reminders: [],
                            itemId: nil,
                            subtasks: [],
                            namePlaceholder: "Task name"
                        ) { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
                            Task {
                                await createTask(name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
                            }
                        }
                    }
                )
                .sheet(
                    isPresented: $showEditSheet,
                    content: {
                        TaskFormSheet(
                            showSheet: $showEditSheet,
                            name: selectedTask?.name ?? "",
                            description: selectedTask?.task_description,
                            priority: selectedTask?.priority,
                            dueDate: selectedTask?.due_date,
                            rrule: selectedTask?.rrule,
                            reminders: selectedTask?.reminders ?? [],
                            itemId: selectedTask?.item_id,
                            subtasks: selectedTask?.subtasks ?? [],
                            namePlaceholder: taskCreationNamePlaceholder
                        ) { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
                            Task {
                                if let selectedTask = selectedTask {
                                    await editTask(id: selectedTask.id, name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
                                }
                            }
                        }
                    }
                )
        }.onAppear {
            Task {
                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.TASKS)
                
                if (shouldSync) {
                    await fetchTasks(completion: false)
                }
            }
            
            Task {
                await fetchTaskTemplateSuggestion()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
            todayDate = Date.now.toLocalDate()
        }
    }
    
    var TaskListView: some View {
        List {
            Section {
                TasksList(
                    dateFilter: todayDate,
                    noDateFilter: true,
                    earlierThanDateFilter: true,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                Text("Today")
                    .fontWeight(.semibold)
                    .font(.title2)
                    .foregroundStyle(UIColor.label.toColor())
                    .textCase(nil)
                    .onTapGesture {
                        taskCreationDueDate = todayDate
                        navigationManager.showCreateTaskSheet = true
                    }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.oneDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(IxDateUtils.oneDayMillis)
                
                VStack(alignment: .leading) {
                    Text("Tomorrow")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.twoDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(IxDateUtils.twoDayMillis)
                
                VStack(alignment: .leading) {
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.threeDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(IxDateUtils.threeDayMillis)
                
                VStack(alignment: .leading) {
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.fourDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(IxDateUtils.fourDayMillis)
                
                VStack(alignment: .leading) {
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.fiveDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(IxDateUtils.fiveDayMillis)
                
                VStack(alignment: .leading) {
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.sixDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(IxDateUtils.sixDayMillis)
                
                VStack(alignment: .leading) {
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(IxDateUtils.sevenDayMillis),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: true,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    taskReverseSorting: reverseSorting) { task in
                        selectedTask = task
                        showEditSheet = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                Text("Later")
                    .fontWeight(.semibold)
                    .font(.title2)
                    .foregroundStyle(UIColor.label.toColor())
                    .textCase(nil)
                    .onTapGesture {
                        taskCreationDueDate = todayDate.addingTimeInterval(IxDateUtils.sevenDayMillis)
                        navigationManager.showCreateTaskSheet = true
                    }
            }
        }
    }
}

#Preview {
    TasksTabView()
        .environmentObject(IxApiClient())
        .environmentObject(ErrorStateService())
        .environmentObject(NavigationManager())
}
