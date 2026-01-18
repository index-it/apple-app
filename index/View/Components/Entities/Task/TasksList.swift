//
//  TasksList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import IxCoreKit
import SwiftData
import SwiftUI

struct TasksList: View {
    private var dateFilter: Date?
    private var noDateFilter: Bool
    private var earlierThanDateFilter: Bool
    private var laterThanDateFilter: Bool

    private var onOpen: (_ task: IxTask) -> Void
    private var onCompletionToggle: (_ task: IxTask) -> Void
    private var onReschedule: (_ task: IxTask) -> Void
    private var onRescheduleNextDay: (_ task: IxTask) -> Void
    private var onDelete: (_ task: IxTask) -> Void

    @Query private var tasks: [IxTask]

    init(
        dateFilter: Date?,
        noDateFilter: Bool,
        earlierThanDateFilter: Bool,
        laterThanDateFilter: Bool,
        taskFilter: TasksFilter,
        taskSorting: TasksSorting,
        sortOrder: SortOrder,
        onOpen: @escaping (_: IxTask) -> Void,
        onCompletionToggle: @escaping (_: IxTask) -> Void,
        onReschedule: @escaping (_: IxTask) -> Void,
        onRescheduleNextDay: @escaping (_: IxTask) -> Void,
        onDelete: @escaping (_: IxTask) -> Void
    ) {
        self.dateFilter = dateFilter
        self.noDateFilter = noDateFilter
        self.earlierThanDateFilter = earlierThanDateFilter
        self.laterThanDateFilter = laterThanDateFilter

        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onReschedule = onReschedule
        self.onRescheduleNextDay = onRescheduleNextDay
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

        var sortDescriptors: [SortDescriptor<IxTask>] = []
        switch taskSorting {
        case .name:
            sortDescriptors.append(SortDescriptor(\IxTask.name, order: sortOrder))
        case .priority:
            sortDescriptors.append(SortDescriptor(\IxTask.priority, order: sortOrder))
            sortDescriptors.append(SortDescriptor(\IxTask.dueDate, order: .forward))
            sortDescriptors.append(SortDescriptor(\IxTask.name, order: .forward))
//        case .manual:
//            sortDescriptor = SortDescriptor(\IxTask.priority, order: sortOrder)
        case .creation:
            sortDescriptors.append(SortDescriptor(\IxTask.createdAt, order: sortOrder))
        }

        // add dueDate to sort 'Later' tasks
        sortDescriptors.append(SortDescriptor(\IxTask.dueDate, order: .forward))

        _tasks = Query(
            filter: filterPredicate,
            sort: sortDescriptors
        )
    }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    var body: some View {
        let subtasksMaxWidth = UIScreen.main.bounds.width / 3

        ForEach(tasks.filter {
            (dateFilter != nil && $0.dueDate != nil && calendar.isDate($0.dueDate!, inSameDayAs: dateFilter!)) ||
                (noDateFilter && $0.dueDate == nil) ||
                (earlierThanDateFilter && $0.dueDate != nil && dateFilter != nil && calendar.compare($0.dueDate!, to: dateFilter!, toGranularity: .day) == .orderedAscending) ||
                (laterThanDateFilter && $0.dueDate != nil && dateFilter != nil && calendar.compare($0.dueDate!, to: dateFilter!, toGranularity: .day) == .orderedDescending)
        }) { task in
            let dateComparison = task.dueDate != nil ? calendar.compare(task.dueDate!, to: dateFilter!, toGranularity: .day) : ComparisonResult.orderedSame

            TaskRow(
                task: task,
                showDate: (task.dueDate != nil && dateComparison == .orderedAscending) || (task.dueDate != nil && dateFilter != nil && dateComparison == .orderedDescending),
                redDate: task.dueDate != nil && dateComparison == .orderedAscending,
                subtasksMaxWidth: subtasksMaxWidth,
                onOpen: onOpen,
                onCompletionToggle: onCompletionToggle,
                onDelete: onDelete
            ).swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    onDelete(task)
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .labelStyle(.iconOnly)
                        .tint(.red)
                }
            }.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    onCompletionToggle(task)
                } label: {
                    Label(task.completed ? "Uncomplete" : "Complete", systemImage: task.completed ? "xmark" : "checkmark")
                        .labelStyle(.iconOnly)
                }.tint(task.completed ? .orange : .accentColor)

                Button {
                    onRescheduleNextDay(task)
                } label: {
                    Image(systemName: "arrow.uturn.down")
                        .rotationEffect(.degrees(90))
                }.tint(.gray)

                Button {
                    onReschedule(task)
                } label: {
                    Label("Reschedule", systemImage: "calendar")
                        .labelStyle(.iconOnly)
                }.tint(.gray)
            }
        }
    }
}
