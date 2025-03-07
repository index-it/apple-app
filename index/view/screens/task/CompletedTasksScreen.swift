//
//  CompletedTasksScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI

struct CompletedTasksScreen: View {
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.modelContext) private var context

    func fetchTasks() async {
        do {
            let tasks = try await ixApiClient.getTasks(completed: true)
            
            try context.transaction {
                try context.delete(
                    model: IxTask.self,
                    where: #Predicate { task in
                        task.completed
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
    
    var body: some View {
        NavigationView {
            CompletedTasksList { task in
                
            } onCompletionToggle: { task in
                
            } onEdit: { task in
                
            } onDelete: { task in
                
            }
            .navigationTitle("Completed tasks")
            .onAppear {
                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.COMPLETED_TASKS)
                
                if shouldSync {
                    Task {
                        await fetchTasks()
                    }
                }
            }
        }
    }
}

#Preview {
    CompletedTasksScreen()
}
