//
//  CompletedTasksList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/03/25.
//

import IxCoreKit
import SwiftData
import SwiftUI

struct CompletedTasksList: View {
    private var onOpen: (_ task: IxTask) -> Void
    private var onCompletionToggle: (_ task: IxTask) -> Void
    var onPrioritize: (_ priority: Int?, IxTask) -> Void
    var onReschedule: (_ nextDay: Bool, IxTask) -> Void
    var onMoveToCalendar: (IxTask) -> Void
    var onOpenConnectedItem: (_ listId: String, _ itemId: String, IxTask) -> Void
    private var onDelete: (_ task: IxTask) -> Void

    @Query private var tasks: [IxTask]

    init(
        onOpen: @escaping (_: IxTask) -> Void,
        onCompletionToggle: @escaping (_: IxTask) -> Void,
        onPrioritize: @escaping (_ priority: Int?, IxTask) -> Void,
        onReschedule: @escaping (_ nextDay: Bool, IxTask) -> Void,
        onMoveToCalendar: @escaping (IxTask) -> Void,
        onOpenConnectedItem: @escaping (_ listId: String, _ itemId: String, IxTask) -> Void,
        onDelete: @escaping (_: IxTask) -> Void
    ) {
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onPrioritize = onPrioritize
        self.onReschedule = onReschedule
        self.onMoveToCalendar = onMoveToCalendar
        self.onOpenConnectedItem = onOpenConnectedItem
        self.onDelete = onDelete

        let filterPredicate = #Predicate<IxTask> { task in
            task.completed
        }

        _tasks = Query(filter: filterPredicate, sort: [SortDescriptor(\IxTask.completedAt, order: .reverse)])
    }

    var body: some View {
        let subtasksMaxWidth = UIScreen.main.bounds.width / 3

        List(tasks) { task in
            TaskRow(
                task: task,
                showDate: true,
                redDate: false,
                subtasksMaxWidth: subtasksMaxWidth,
                onOpen: onOpen,
                onCompletionToggle: onCompletionToggle,
                onPrioritize: onPrioritize,
                onReschedule: onReschedule,
                onMoveToCalendar: onMoveToCalendar,
                onOpenConnectedItem: onOpenConnectedItem,
                onDelete: onDelete
            ).swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    onDelete(task)
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }.if(task.rrule == nil) { view in
                view.swipeActions(edge: .leading) {
                    Button {
                        onCompletionToggle(task)
                    } label: {
                        Label(task.completed ? "Uncomplete" : "Complete", systemImage: task.completed ? "xmark" : "checkmark")
                    }.tint(task.completed ? .orange : .accentColor)
                }
            }
        }.overlay {
            if tasks.isEmpty {
                ContentUnavailableView {
                    Label("No completed tasks", systemImage: "binoculars")
                } description: {
                    Text("You haven't completed any task yet!")
                }
            }
        }
    }
}

#Preview {
    CompletedTasksList { _ in
    } onCompletionToggle: { _ in
    } onPrioritize: {_, _ in
    } onReschedule: {_, _ in
    } onMoveToCalendar: { _ in
    } onOpenConnectedItem: { _, _, _ in
    } onDelete: { _ in
    }
}
