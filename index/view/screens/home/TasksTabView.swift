//
//  TasksHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import SwiftData

struct TasksTabView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.modelContext) private var context
    
    @AppStorage("user") var user: User?
    
    // MARK: Date
    @State private var todayDate: Date = Date.now.toLocalDate()
    
    // MARK: Task creation
    @State private var showCreationSheet = false
    // TODO: All props
    
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
            context.delete(task)
            context.insert(task)
            try context.save()
        }
    }
    
    // MARK: - Suggestions
    func fetchTaskTemplateSuggestion() async {
        do {
            let template = try await ixApiClient.getTaskTemplateSuggestion()
            
            // TODO: Assign to create props
        } catch {
            
        }
    }
    
    // MARK: - Task CRUD
    func fetchTasks() async {
        do {
            let tasks = try await ixApiClient.getTasks(completed: false)
            
            try context.transaction {
                try context.delete(
                    model: IxTask.self,
                    where: #Predicate { task in
                        !task.completed
                    }
                )
                
                tasks.forEach { ixTask in
                    context.insert(ixTask)
                }
                
                try context.save()
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
            
            context.insert(task)
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
        } catch {
            errorService.insert(.localizedError(title: "Error \(completed ? "completing" : "uncompleting") task", error: error))
        }
    }
    
    
    func deleteTask(id: String) async {
        do {
            try await ixApiClient.deleteTask(taskId: id)
            try context.delete(model: IxTask.self, where: #Predicate { $0.id == id })
        } catch IxApiClientError.NotFound {
            do { try context.delete(model: IxTask.self, where: #Predicate { $0.id == id }) } catch {}
        } catch {
            errorService.insert(.localizedError(title: "Error deleting task", error: error))
        }
    }
    
    var body: some View {
        NavigationView {
            TaskListView
                .navigationTitle("Your tasks")
                .floatingActionButton("plus", action: {
                    showCreationSheet = true
                })
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Completed tasks", systemImage: "book.closed") {
                            navigationManager.push(navigationRoute: .completedTasks)
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
                        Button("Delete", role: .destructive) {
                            if let selectedTask {
                                Task {
                                    await deleteTask(id: selectedTask.id)
                                }
                            }
                        }
                        
                        Button("Keep", role: .cancel) {
                            showDeleteConfirmationDialog = false
                        }
                    },
                    message: {
                        Text("Are you sure you want to delete the task \(selectedTask?.name ?? "")?")
                    }
                )
//                .sheet(
//                    isPresented: $showCreationSheet,
//                    content: {
//                        TaskFormSheet(
//                            showSheet: $showCreationSheet,
//                            name: "",
//                            category: selectedCategory,
//                            link: nil,
//                            note: nil,
//                            categories: categories,
//                            namePlaceholder: newItemNamePlaceholder
//                        ) { name, category, link, note in
//                            Task {
//                                await createItem(listId: listId, name: name, categoryId: category?.id, link: link, note: note)
//                            }
//                        }
//                })
        }.onAppear {
            Task {
                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.TASKS)
                
                if (shouldSync) {
                    await fetchTasks()
                }
            }
            
            Task {
                await fetchTaskTemplateSuggestion()
            }
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                VStack(alignment: .leading) {
                    let date = todayDate.addingTimeInterval(IxDateUtils.oneDayMillis)
                    
                    Text("Tomorrow")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .textCase(nil)
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                VStack(alignment: .leading) {
                    let date = todayDate.addingTimeInterval(IxDateUtils.twoDayMillis)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                VStack(alignment: .leading) {
                    let date = todayDate.addingTimeInterval(IxDateUtils.threeDayMillis)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                VStack(alignment: .leading) {
                    let date = todayDate.addingTimeInterval(IxDateUtils.fourDayMillis)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                VStack(alignment: .leading) {
                    let date = todayDate.addingTimeInterval(IxDateUtils.fiveDayMillis)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
                    } onDelete: { task in
                        selectedTask = task
                        showDeleteConfirmationDialog = true
                    }
            } header: {
                VStack(alignment: .leading) {
                    let date = todayDate.addingTimeInterval(IxDateUtils.sixDayMillis)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionHeading.string(from: date))
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(UIColor.label.toColor())
                        .textCase(nil)
                    
                    Text(IxDateUtils.Formatters.shared.taskSectionSubheading.string(from: date))
                        .font(.caption)
                        .textCase(nil)
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
                        
                    } onCompletionToggle: { task in
                        Task {
                            await setTaskCompletion(id: task.id, completed: !task.completed)
                        }
                    } onEdit: { task in
                        selectedTask = task
                        showEditSheet = true
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
