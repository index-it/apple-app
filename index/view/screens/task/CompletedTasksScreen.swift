//
//  CompletedTasksScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI
import IxCoreKit

struct CompletedTasksScreen: View {
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
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
            }
        } catch {
            errorService.insert(.localizedError(title: "Error loading tasks", error: error))
        }
    }
    
    var body: some View {
        NavigationView {
            CompletedTasksList { task in
                
            } onCompletionToggle: { task in
                
            } onDelete: { task in
                
            }
            .navigationTitle("Completed tasks")
            .onAppear {
                Task {
                    let shouldSync = await SyncRegister.shared.hasExpired(SyncResource.completedTasks)
                    
                    if shouldSync {
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
