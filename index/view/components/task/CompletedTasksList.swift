//
//  CompletedTasksList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/03/25.
//

import SwiftUI
import SwiftData

struct CompletedTasksList: View {
    private var onOpen: (_ task: IxTask) -> ()
    private var onCompletionToggle: (_ task: IxTask) -> ()
    private var onEdit: (_ task: IxTask) -> ()
    private var onDelete: (_ task: IxTask) -> ()
    
    @Query private var tasks: [IxTask]
    
    init(
        onOpen: @escaping (_: IxTask) -> Void,
        onCompletionToggle: @escaping (_: IxTask) -> Void,
        onEdit: @escaping (_: IxTask) -> Void,
        onDelete: @escaping (_: IxTask) -> Void
    ) {
        self.onOpen = onOpen
        self.onCompletionToggle = onCompletionToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let filterPredicate = #Predicate<IxTask> { task in
            task.completed
        }
        
        _tasks = Query(filter: filterPredicate, sort: [SortDescriptor(\IxTask.completed_at, order: .reverse)])
    }
    
    var body: some View {
        List(tasks) { task in
            TaskRow(
                task: task,
                showDate: true,
                redDate: false,
                onOpen: onOpen,
                onCompletionToggle: onCompletionToggle,
                onEdit: onEdit,
                onDelete: onDelete
            ).swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete(task)
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    onCompletionToggle(task)
                } label: {
                    Label(task.completed ? "Uncomplete" : "Complete", systemImage: task.completed ? "xmark" : "checkmark")
                }.tint(task.completed ? .orange : .accentColor)
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
    CompletedTasksList { task in
            
        } onCompletionToggle: { task in
            
        } onEdit: { task in
            
        } onDelete: { task in
            
        }
}
