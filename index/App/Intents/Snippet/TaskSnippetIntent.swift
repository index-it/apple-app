//
//  TaskSnippetIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit
import SwiftData
import SwiftUI

struct TaskSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Task Snippet"

    @Parameter var task: IxTaskEntity
    @Dependency var modelContainer: ModelContainer

    init(task: IxTaskEntity) {
        self.task = task
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        return .result(
            view: TaskSnippetIntentView(task: task)
        )
    }
}

struct TaskSnippetIntentView: View {
    let task: IxTaskEntity

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(intent: CompleteTaskByIdIntent(taskId: task.id)) {
                    Label("Complete", systemImage: task.completed ? "inset.filled.circle" : "circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading) {
                    Text(task.name)
                        .lineLimit(1)
                        .font(.footnote)

                    if !task.description.isEmpty {
                        Text(task.description)
                            .lineLimit(2)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        if let dueDate = task.dueDate {
                            Text(DateHelper.Formatters.taskRowDate.string(from: dueDate))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if let priority = task.priority {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(IxTask.priorityColor(priority))
                }
            }
        }
    }
}

#Preview {
    TaskSnippetIntentView(
        task: IxTaskEntity(task: .mock(name: "Test task", description: "Test description", priority: 1))
    )
    .padding()
}
