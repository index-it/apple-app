//
//  TasksDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI
import SwiftData

struct TasksList: View {
    private var dateFilter: Date?
    private var noDateFilter: Bool
    private var earlierThanDateFilter: Bool
    private var laterThanDateFilter: Bool
    
    private var onOpen: (_ task: IxTask) -> ()
    private var onCompletionToggle: (_ task: IxTask) -> ()
    private var onDelete: (_ task: IxTask) -> ()
    
    @Query private var tasks: [IxTask]
    
    init(
        dateFilter: Date?,
        noDateFilter: Bool,
        earlierThanDateFilter: Bool,
        laterThanDateFilter: Bool,
        taskFilter: TaskFilter,
        taskSorting: TaskSorting,
        taskReverseSorting: Bool,
        onOpen: @escaping (_: IxTask) -> Void,
        onCompletionToggle: @escaping (_: IxTask) -> Void,
        onDelete: @escaping (_: IxTask) -> Void
    ) {
        self.dateFilter = dateFilter
        self.noDateFilter = noDateFilter
        self.earlierThanDateFilter = earlierThanDateFilter
        self.laterThanDateFilter = laterThanDateFilter
        
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onDelete = onDelete
        
        let completedFilter = taskFilter == .completed
        
        let filterPredicate = #Predicate<IxTask> { task in
            (completedFilter && task.completed) ||
            (!completedFilter && !task.completed)
            // fuck swift compiler
//            ) &&
//            (
//                (dateFilter != nil && task.due_date != nil && task.due_date! == dateFilter!) ||
//                (noDateFilter && task.due_date == nil) ||
//                (earlierThanDateFilter && task.due_date != nil && dateFilter != nil && task.due_date! <= dateFilter!)
//                (laterThanDateFilter && task.due_date != nil && dateFilter != nil && task.due_date! >= dateFilter!)
//            )
//            let completionFilterResult: Bool
//            
//            if taskFilter == .completed {
//                completionFilterResult = task.completed == true
//            } else {
//                completionFilterResult = task.completed == false
//            }
//            
//            var dateFilterResult = false
//            if let date = dateFilter, let dueDate = task.due_date {
//                dateFilterResult = dueDate == date
//            }
//            
//            if noDateFilter && task.due_date == nil {
//                dateFilterResult = true
//            }
//            
//            if let dueDate = task.due_date, let date = dateFilter {
//                if laterThanDateFilter && dueDate >= date {
//                    dateFilterResult = true
//                }
//            }
        }
        
        let sortOrder = taskSorting == .priority ? (taskReverseSorting ? SortOrder.forward : SortOrder.reverse) : (taskReverseSorting ? SortOrder.reverse : SortOrder.forward)
        
        let sortDescriptor: SortDescriptor<IxTask>
        switch taskSorting {
        case .name:
            sortDescriptor = SortDescriptor(\IxTask.name, order: sortOrder)
        case .priority:
            sortDescriptor = SortDescriptor(\IxTask.priority, order: sortOrder)
        case .creation:
            sortDescriptor = SortDescriptor(\IxTask.created_at, order: sortOrder)
        }
       
        _tasks = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }
    
    var body: some View {
        let subtasksMaxWidth = UIScreen.main.bounds.width / 3
        
        ForEach(tasks.filter {
            (dateFilter != nil && $0.due_date != nil && calendar.isDate($0.due_date!, inSameDayAs: dateFilter!)) ||
            (noDateFilter && $0.due_date == nil) ||
            (earlierThanDateFilter && $0.due_date != nil && dateFilter != nil && calendar.compare($0.due_date!, to: dateFilter!, toGranularity: .day) == .orderedAscending) ||
            (laterThanDateFilter && $0.due_date != nil && dateFilter != nil && calendar.compare($0.due_date!, to: dateFilter!, toGranularity: .day) == .orderedDescending)
        }) { task in
            
            
            let dateComparison = task.due_date != nil ? calendar.compare(task.due_date!, to: dateFilter!, toGranularity: .day) : ComparisonResult.orderedSame
            
            TaskRow(
                task: task,
                showDate: (task.due_date != nil && dateComparison == .orderedAscending) || (task.due_date != nil && dateFilter != nil && dateComparison == .orderedDescending),
                redDate: task.due_date != nil && dateComparison == .orderedAscending,
                subtasksMaxWidth: subtasksMaxWidth,
                onOpen: onOpen,
                onCompletionToggle: onCompletionToggle,
                onDelete: onDelete
            ).swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    onDelete(task)
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .tint(.red)
                }
            }.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    onCompletionToggle(task)
                } label: {
                    Label(task.completed ? "Uncomplete" : "Complete", systemImage: task.completed ? "xmark" : "checkmark")
                }.tint(task.completed ? .orange : .accentColor)
            }
        }
    }
}

#Preview {
    TasksList(
        dateFilter: nil,
        noDateFilter: false,
        earlierThanDateFilter: false,
        laterThanDateFilter: false,
        taskFilter: .uncompleted,
        taskSorting: .name,
        taskReverseSorting: false) { task in
            
        } onCompletionToggle: { task in
            
        } onDelete: { task in
            
        }
}
