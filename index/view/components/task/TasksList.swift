//
//  TasksDisplayer.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI
import SwiftData

struct TasksList: View {
    private var onOpen: (_ task: IxTask) -> ()
    private var onCompletionToggle: (_ task: IxTask) -> ()
    private var onEdit: (_ task: IxTask) -> ()
    private var onDelete: (_ task: IxTask) -> ()
    private var onSwipeLeft: (_ taks: IxTask, _ completionAction: @escaping () -> ()) -> ()
    private var onSwipeRight: (_ task: IxTask, _ completionAction: @escaping () -> ()) -> ()
    
    @Query private var tasks: [IxTask]
    
    init(
        dateFilter: Date?,
        noDateFilter: Bool,
        laterThanDateFilter: Bool,
        taskFilter: TaskFilter,
        taskSorting: TaskSorting,
        taskReverseSorting: Bool,
        onOpen: @escaping (_: IxTask) -> Void,
        onCompletionToggle: @escaping (_: IxTask) -> Void,
        onEdit: @escaping (_: IxTask) -> Void,
        onDelete: @escaping (_: IxTask) -> Void,
        onSwipeLeft: @escaping (_: IxTask, _: @escaping () -> Void) -> Void,
        onSwipeRight: @escaping (_: IxTask, _: @escaping () -> Void) -> Void
    ) {
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        
        let filterPredicate = #Predicate<IxTask> { task in
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
            
            task.completed
        }
        
//        let sortOrder = taskReverseSorting ? SortOrder.reverse : SortOrder.forward
        
//        let sortDescriptor: SortDescriptor<IxTask>
//        switch taskSorting {
//        case .name:
//            sortDescriptor = SortDescriptor(\IxTask.name, order: sortOrder)
//        case .priority:
//            sortDescriptor = SortDescriptor(\IxTask.priority, order: sortOrder)
//        case .creation:
//            sortDescriptor = SortDescriptor(\IxTask.created_at, order: sortOrder)
//        }
       
//        _tasks = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    TasksList(
        dateFilter: nil,
        noDateFilter: false,
        laterThanDateFilter: false,
        taskFilter: .uncompleted,
        taskSorting: .name,
        taskReverseSorting: false) { task in
            
        } onCompletionToggle: { task in
            
        } onEdit: { task in
            
        } onDelete: { task in
            
        } onSwipeLeft: { task, fun in
            
        } onSwipeRight: { task, fun in
            
        }

}
