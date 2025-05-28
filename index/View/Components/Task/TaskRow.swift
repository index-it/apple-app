//
//  TaskCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI
import SwiftData
import IxCoreKit

struct TaskRow: View {
    private var task: IxTask
    private var showDate: Bool
    private var redDate: Bool
    private var subtasksMaxWidth: CGFloat
    
    var onOpen: (IxTask) -> ()
    var onCompletionToggle: (IxTask) -> ()
    var onDelete: (IxTask) -> ()
    
    @Query var taskItem: [IxListItem]
    
    init(
        task: IxTask,
        showDate: Bool,
        redDate: Bool,
        subtasksMaxWidth: CGFloat,
        onOpen: @escaping (IxTask) -> Void,
        onCompletionToggle: @escaping (IxTask) -> Void,
        onDelete: @escaping (IxTask) -> Void
    ) {
        self.task = task
        self.showDate = showDate
        self.redDate = redDate
        self.subtasksMaxWidth = subtasksMaxWidth
        
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onDelete = onDelete
        
        let itemId = task.itemId
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
            subtasksMaxWidth: subtasksMaxWidth,
            onOpen: onOpen,
            onCompletionToggle: onCompletionToggle,
            onDelete: onDelete
        )
    }
}

struct TaskRowContentView: View {
    var task: IxTask
    var item: IxListItem?
    var showDate: Bool
    var redDate: Bool
    var subtasksMaxWidth: CGFloat
    
    var onOpen: (IxTask) -> ()
    var onCompletionToggle: (IxTask) -> ()
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
    
    init(
        task: IxTask,
        item: IxListItem?,
        showDate: Bool,
        redDate: Bool,
        subtasksMaxWidth: CGFloat,
        onOpen: @escaping (IxTask) -> Void,
        onCompletionToggle: @escaping (IxTask) -> Void,
        onDelete: @escaping (IxTask) -> Void
    ) {
        self.task = task
        self.showDate = showDate
        self.redDate = redDate
        self.subtasksMaxWidth = subtasksMaxWidth
        
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onDelete = onDelete
        
        let listId = item?.listId
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
        
        
        let categoryId = item?.categoryId
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
        Button {
            onOpen(task)
        } label: {
            TaskRowContent
        }
        .listRowBackground(taskItemList.first?.color.toColorOrNil())
    }
    
    var TaskRowContent: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
//                    HStack {
//                        if task.rrule != nil {
//                            Image(systemName: "repeat")
//                                .foregroundStyle(.secondary)
//                        }
//                    }
                    
                    Text(task.name)
                        .multilineTextAlignment(.leading)
                        .if(task.completed) { view in
                            view.strikethrough()
                        }
                    
                    if let listName = taskItemList.first?.name {
                        Text([listName, taskItemCategory.first?.name].compactMap { $0 }.joined(separator: " / "))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    
                    if showDate {
                        Text(task.taskRowDate)
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
                            
                            Spacer(minLength: subtasksMaxWidth)
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
