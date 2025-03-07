//
//  TaskCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI
import SwiftData

struct TaskRow: View {
    var task: IxTask
    var showDate: Bool
    var redDate: Bool
    
    var onOpen: (IxTask) -> ()
    var onCompletionToggle: (IxTask) -> ()
    var onEdit: (IxTask) -> ()
    var onDelete: (IxTask) -> ()
    
    @Query var taskItem: [IxListItem]
    
    init(
        task: IxTask,
        showDate: Bool,
        redDate: Bool,
        onOpen: @escaping (IxTask) -> Void,
        onCompletionToggle: @escaping (IxTask) -> Void,
        onEdit: @escaping (IxTask) -> Void,
        onDelete: @escaping (IxTask) -> Void
    ) {
        self.task = task
        self.showDate = showDate
        self.redDate = redDate
        
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let itemId = task.item_id
        var itemDescriptor: FetchDescriptor<IxListItem>
        
        if itemId != nil {
            itemDescriptor = FetchDescriptor<IxListItem>(
                predicate: #Predicate { item in
                    item.id == itemId!
                }
            )
        } else {
            itemDescriptor = FetchDescriptor<IxListItem>(
                predicate: #Predicate { _ in false }
            )
        }
        itemDescriptor.fetchLimit = 1
        _taskItem = Query(itemDescriptor)
    }
    
    var body: some View {
        TaskRowContentView(
            task: task,
            item: taskItem.first,
            showDate: showDate,
            redDate: redDate,
            onOpen: onOpen,
            onCompletionToggle: onCompletionToggle,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }
}

struct TaskRowContentView: View {
    var task: IxTask
    var item: IxListItem?
    var showDate: Bool
    var redDate: Bool
    
    var onOpen: (IxTask) -> ()
    var onCompletionToggle: (IxTask) -> ()
    var onEdit: (IxTask) -> ()
    var onDelete: (IxTask) -> ()
    
    var priorityColor: Color {
        switch task.priority {
        case 0: .gray
        case 1: .green
        case 2: .orange
        case 3: .red
        default: .gray
        }
    }
    
    @Query var taskItemCategory: [IxListCategory]
    @Query var taskItemList: [IxList]
    
    @State private var subtasksSpacerWidth: CGFloat = 0
    
    init(
        task: IxTask,
        item: IxListItem?,
        showDate: Bool,
        redDate: Bool,
        onOpen: @escaping (IxTask) -> Void,
        onCompletionToggle: @escaping (IxTask) -> Void,
        onEdit: @escaping (IxTask) -> Void,
        onDelete: @escaping (IxTask) -> Void
    ) {
        self.task = task
        self.showDate = showDate
        self.redDate = redDate
        
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let listId = item?.list_id
        var listDescriptor: FetchDescriptor<IxList>
        
        if (listId != nil) {
            listDescriptor = FetchDescriptor<IxList>(
               predicate: #Predicate { list in
                   list.id == listId!
               }
           )
        } else {
            listDescriptor = FetchDescriptor<IxList>(
               predicate: #Predicate { _ in false }
           )
        }
        
        listDescriptor.fetchLimit = 1
        _taskItemList = Query(listDescriptor)
        
        
        let categoryId = item?.category_id
        var categoryDescriptor: FetchDescriptor<IxListCategory>
        
        if (categoryId != nil) {
            categoryDescriptor = FetchDescriptor<IxListCategory>(
               predicate: #Predicate { category in
                   category.id == categoryId!
               }
           )
        } else {
            categoryDescriptor = FetchDescriptor<IxListCategory>(
               predicate: #Predicate { _ in false }
           )
        }
        categoryDescriptor.fetchLimit = 1
        _taskItemCategory = Query(categoryDescriptor)
    }
    
    var body: some View {
        Menu {
            Button(task.completed ? "Uncomplete" : "Complete", systemImage: task.completed ? "xmark" : "checkmark") {
                onCompletionToggle(task)
            }
            
            
            Section {
                Button("Edit", systemImage: "pencil") {
                    onEdit(task)
                }
                
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDelete(task)
                    }
                    
                    Button("Cancel", role: .cancel) {}
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            TaskRowContent
                .onGeometryChange(for: CGSize.self, of: \.size) { newValue in
                    subtasksSpacerWidth = newValue.width / 2
                }
        }
        .listRowBackground(taskItemList.first?.color.toColorOrNil())
    }
    
    var TaskRowContent: some View {
        VStack(alignment: .leading) {
            HStack {
                
                VStack(alignment: .leading) {
                    HStack {
                        
                        
                        Text(task.name)
                            .multilineTextAlignment(.leading)
                            .if(task.completed) { view in
                                view.strikethrough()
                            }
                    }
                    
                    if let listName = taskItemList.first?.name {
                        Text([listName, taskItemCategory.first?.name].compactMap { $0 }.joined(separator: " / "))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    
                    if showDate {
                        Text(task.dueDateString())
                            .foregroundStyle(redDate ? .red : .secondary)
                            .textCase(.uppercase)
                            .font(.caption)
                    }
                    
                    if !task.subtasks.isEmpty {
                        let sortedSubTasks = task.subtasks.sorted { $0.completed && !$1.completed }
                        
                        
                        HStack(spacing: 3) {
                            ForEach(sortedSubTasks.indices, id: \.self) { index in
                                UnevenRoundedRectangle(cornerRadii: .init(
                                    topLeading: index == 0 ? 50 : 0,
                                    bottomLeading: index == 0 ? 50 : 0,
                                    bottomTrailing: index == (task.subtasks.count - 1) ? 50 : 0,
                                    topTrailing: index == (task.subtasks.count - 1) ? 50 : 0
                                ))
                                .frame(height: 6)
                                .foregroundColor(sortedSubTasks[index].completed ? .primary : .gray)
                            }
                            
                            Spacer(minLength: subtasksSpacerWidth)
                        }.padding(.leading, 2)
                    }
                }
                
                Spacer()
                
                if task.priority != nil {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(priorityColor)
                }
                
            }
            
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(taskItemList.first?.color.toColorOrNil()?.contrastColor() ?? UIColor.label.toColor())
    }
}

#Preview {
    @State var tasks: [IxTask] = [
        IxTask(id: "id1", userId: "id", itemId: nil, name: "Buy Gocciole", description: "at the Conad today", subtasks: [IxSubTask(name: "Pavesi", completed: false), IxSubTask(name: "Choco", completed: true), IxSubTask(name: "Another", completed: false)], dueDate: .now, rrule: nil, completed: true, priority: 2, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: Int64(Date.now.addingTimeInterval(60 * 60 * 24 * -2).timeIntervalSince1970)),
        
        IxTask(id: "id2", userId: "id", itemId: nil, name: "Buy more Gocciole", description: "at the Conad today", subtasks: [IxSubTask(name: "Pavesi", completed: false), IxSubTask(name: "Choco", completed: true)], dueDate: nil, rrule: nil, completed: false, priority: 1, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil),
        
        IxTask(id: "id3", userId: "id", itemId: nil, name: "Clean kitchen", description: "Before guests arrive", subtasks: [IxSubTask(name: "Sweep", completed: false), IxSubTask(name: "Mop", completed: false)], dueDate: .now.addingTimeInterval(86400), rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil),
        
        IxTask(id: "id4", userId: "id", itemId: nil, name: "Finish homework", description: "Math and Physics", subtasks: [IxSubTask(name: "Math problems", completed: true), IxSubTask(name: "Physics report", completed: false)], dueDate: .now.addingTimeInterval(172800), rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil),
        
        IxTask(id: "id5", userId: "id", itemId: nil, name: "Call mechanic", description: "Car check-up", subtasks: [], dueDate: nil, rrule: nil, completed: false, priority: nil, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil)
    ]
    
    List {
        ForEach($tasks, id: \.id) { $task in
            TaskRow(task: task, showDate: task.due_date != nil, redDate: false) { task in
                // Handle task open
            } onCompletionToggle: { task in
                task.completed.toggle()
            } onEdit: { task in
                // Handle edit
            } onDelete: { task in
                // Handle delete
            }
        }

    }
}
