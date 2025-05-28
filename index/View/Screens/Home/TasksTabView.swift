//
//  TasksHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import SwiftData
import WidgetKit
import IxCoreKit

struct TasksTabView: View {
    @Environment(\.modelContext) private var context
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var errorService: ErrorStateService
    
    @AppStorage(AppStorageKeys.loggedInUser) var user: User?
    @State private var showPaywall = false
    
    // MARK: Date
    @State private var todayDate: Date = Date.now.toLocalDate()
    
    // MARK: Task creation
    @State private var isAddingTask = false
    @State private var taskCreationDueDate: Date? = nil
    @State private var taskCreationNamePlaceholder = "Task name"
    
    // MARK: Selected task
    @State private var selectedTask: IxTask? = nil
    @State private var isEditingTask = false
    @State private var showDeleteConfirmationDialog = false
    
    // MARK: Sorting and filtering
    @AppStorage(AppStorageKeys.Tasks.sorting) private var sorting = AppStorageKeys.Defaults.tasksSorting
    @AppStorage(AppStorageKeys.Tasks.sortOrder) private var sortOrder = AppStorageKeys.Defaults.tasksSortOrder
    
    private func saveTask(_ task: IxTask) async throws {
        try context.transaction {
            context.insert(task)
        }
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
        } catch IxApiClientError.proRequired(_) {
            showPaywall = true
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
        } catch IxApiClientError.notFound {
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
                .floatingActionButton("plus") {
                    // TODO
                }
                .paywallCover(isPresented: $showPaywall)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            CompletedTasksList { task in
                                selectedTask = task
                                isEditingTask = true
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
                    
//                    ToolbarItem(placement: .secondaryAction) {
//                        Picker(selection: $sorting) {
//                            ForEach(TasksSorting.allCases) { filter in
//                                Text(filter.label)
//                                    .tag(filter)
//                            }
//                        } label: {
//                            Label("Sorting", systemImage: "arrow.up.arrow.down")
//                        }.pickerStyle(.menu)
//                    }
//                    
//                    ToolbarItem(placement: .secondaryAction) {
//                        Toggle("Reverse", isOn: $reverseSorting)
//                    }
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
                    isPresented: $isAddingTask,
                    content: { [taskCreationDueDate] in
                        TaskEditor(
                            isPresented: $isAddingTask,
                            addingNew: true,
                            name: "",
                            description: nil,
                            priority: nil,
                            dueDate: taskCreationDueDate,
                            rrule: nil,
                            reminders: [],
                            itemId: nil,
                            subtasks: [],
                        ) { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
                            Task {
                                await createTask(name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
                            }
                        }
                    }
                )
                .sheet(
                    isPresented: $isEditingTask,
                    content: {
                        TaskEditor(
                            isPresented: $isEditingTask,
                            addingNew: false,
                            name: selectedTask?.name ?? "",
                            description: selectedTask?.taskDescription,
                            priority: selectedTask?.priority,
                            dueDate: selectedTask?.dueDate,
                            rrule: selectedTask?.rrule,
                            reminders: selectedTask?.reminders ?? [],
                            itemId: selectedTask?.itemId,
                            subtasks: selectedTask?.subtasks ?? [],
                        ) { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
                            Task {
                                if let selectedTask = selectedTask {
                                    await editTask(id: selectedTask.id, name: name, description: description, dueDate: dueDate, rrule: rrule, reminders: reminders, subtasks: subtasks, priority: priority, itemId: itemId)
                                }
                            }
                        }
                    }
                )
        }
        .onAppear {
            Task {
                let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.tasks)
                
                if (shouldSync) {
                    await fetchTasks(completion: false)
                }
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
                    sortOrder: sortOrder
                ) { task in
                    selectedTask = task
                    isEditingTask = true
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
                        // TODO
//                        navigationManager.showCreateTaskSheet = true
                    }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.oneDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(DateHelper.oneDaySeconds)
                
                VStack(alignment: .leading) {
                    Text("Tomorrow")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(DateHelper.Formatters.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
//                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.twoDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(DateHelper.twoDaySeconds)
                
                VStack(alignment: .leading) {
                    Text(DateHelper.Formatters.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(DateHelper.Formatters.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
//                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.threeDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(DateHelper.threeDaySeconds)
                
                VStack(alignment: .leading) {
                    Text(DateHelper.Formatters.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(DateHelper.Formatters.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
//                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.fourDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(DateHelper.fourDaySeconds)
                
                VStack(alignment: .leading) {
                    Text(DateHelper.Formatters.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(DateHelper.Formatters.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
//                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.fiveDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(DateHelper.fiveDaySeconds)
                
                VStack(alignment: .leading) {
                    Text(DateHelper.Formatters.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(DateHelper.Formatters.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
//                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.sixDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: false,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                let date = todayDate.addingTimeInterval(DateHelper.sixDaySeconds)
                
                VStack(alignment: .leading) {
                    Text(DateHelper.Formatters.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(DateHelper.Formatters.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
                }.onTapGesture {
                    taskCreationDueDate = date
//                    navigationManager.showCreateTaskSheet = true
                }
            }
            
            Section {
                TasksList(
                    dateFilter: todayDate.addingTimeInterval(DateHelper.sevenDaySeconds),
                    noDateFilter: false,
                    earlierThanDateFilter: false,
                    laterThanDateFilter: true,
                    taskFilter: .uncompleted,
                    taskSorting: sorting,
                    sortOrder: sortOrder) { task in
                        selectedTask = task
                        isEditingTask = true
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
                        taskCreationDueDate = todayDate.addingTimeInterval(DateHelper.sevenDaySeconds)
//                        navigationManager.showCreateTaskSheet = true
                    }
            }
        }
    }
}
