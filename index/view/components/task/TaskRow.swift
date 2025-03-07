//
//  TaskCard.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI

struct TaskRow: View {
    var task: IxTask
    var color: Color?
    
    var onOpen: (IxTask) -> ()
    var onCompletionToggle: (IxTask) -> ()
    var onEdit: (IxTask) -> ()
    var onDelete: (IxTask) -> ()
    
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
            TaskCardContent
        }
    }
    
    var TaskCardContent: some View {
        HStack {
            
            if task.completed {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
            }
            
            Text(task.name)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }.padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(color?.contrastColor() ?? UIColor.label.toColor())
            .background(color ?? UIColor.secondarySystemBackground.toColor())
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    let task = IxTask(id: "id", userId: "id", itemId: nil, name: "Buy Gocciole", description: "at the conad tuday", subtasks: [IxSubTask(name: "pavesi", completed: false), IxSubTask(name: "choco", completed: false)], dueDate: nil, rrule: nil, completed: false, priority: 2, reminders: [], createdAt: Date.now.currentTimeMillis(), completedAt: nil)
    
    TaskRow(task: task) { task in
        
    } onCompletionToggle: { task in
        task.completed = !task.completed
    } onEdit: { task in
        
    } onDelete: { task in
        
    }.padding()
}
