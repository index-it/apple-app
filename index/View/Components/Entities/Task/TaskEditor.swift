//
//  TaskEditor.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import EventKit
import IxCoreKit
import SwiftData
import SwiftUI

struct TaskEditor: View {
    @Environment(\.showError) private var showError

    @Binding var config: EditorConfig<IxTask>
    private var onSave: () -> Void

    @FocusState private var isNameFocused: Bool

    @FocusState private var subtaskFocusField: Int?
    @State private var isSubtasksDisclosureGroupExpanded = true
    @State private var subtaskCreated = false

    @State private var recurrenceState = RecurrenceState()

    @Query private var items: [IxListItem]

    init(
        config: Binding<EditorConfig<IxTask>>,
        onSave: @escaping () -> Void
    ) {
        _config = config
        self.onSave = onSave

        var itemDescription: FetchDescriptor<IxListItem>

        let itemId = config.entity.itemId.wrappedValue
        if let itemId = itemId {
            itemDescription = FetchDescriptor<IxListItem>(
                predicate: #Predicate { item in
                    item.id == itemId
                }
            )
        } else {
            itemDescription = FetchDescriptor<IxListItem>(
                predicate: #Predicate { _ in false }
            )
        }

        itemDescription.fetchLimit = 1
        _items = Query(itemDescription)
    }

    private func onSaveSubmit() {
        config.entity.rrule = recurrenceState.generateRRule()

        onSave()
    }

    var body: some View {
        NavigationView {
            Form {
                nameAndDescriptionSection

                prioritySection

                subtasksSection

                TaskDateSection(
                    config: $config,
                    isTaskNameFocused: _isNameFocused,
                    recurrenceState: recurrenceState
                )

                if config.entity.itemId != nil {
                    connectedItemSection
                }
            }
            .navigationTitle(config.mode == .create ? "Add Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationSubtitle(config.multi ? "Adding multiple tasks" : "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        config.isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSaveSubmit()
                    } label: {
                        if config.loading {
                            ProgressView()
                        } else {
                            Label("Save", systemImage: "checkmark")
                                .labelStyle(.titleOnly)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!config.entity.validationRes.isSuccess)
                }
            }
        }
        .onAppear {
            if config.entity.name.isEmpty {
                isNameFocused = true
            }

            DispatchQueue.global(qos: .userInitiated).async {
                recurrenceState.parseRRule(config.entity.rrule)
            }
        }
    }

    // MARK: - Name and Description Section

    var nameAndDescriptionSection: some View {
        Section {
            TextField("Name", text: $config.entity.name)
                .focused($isNameFocused)

            TextField("Description", text: $config.entity.taskDescription ?? "", axis: .vertical)
        }
    }

    // MARK: - Priority Section

    var prioritySection: some View {
        Picker("Priority", systemImage: "flag.fill", selection: $config.entity.priority) {
            Section {
                Text("None")
                    .tag(nil as Int?)
            }

            Section {
                Text("Very low")
                    .tag(0)

                Text("Low")
                    .tag(1)

                Text("Medium")
                    .tag(2)

                Text("High")
                    .tag(3)
            }
        }.labelStyle(ListLabelStyle(color: .red))
    }

    // MARK: - Subtasks Section

    var subtasksSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isSubtasksDisclosureGroupExpanded) {
                subtasksList

                addSubtaskButton
            } label: {
                Label("Subtasks", systemImage: "checklist.unchecked")
                    .labelStyle(ListLabelStyle(color: .brown))
            }

        } header: {
            Text("Subtasks")
        }
    }

    // MARK: - Subtasks List

    var subtasksList: some View {
        ForEach(Array(config.entity.subtasks.enumerated()), id: \.offset) { index, subtask in
            HStack {
                Button {
                    config.entity.subtasks[index].completed = !subtask.completed
                } label: {
                    Image(systemName: subtask.completed ? "inset.filled.circle" : "circle")
                }

                TextField(
                    "Insert name",
                    text: $config.entity.subtasks[index].name
                )
                .focused($subtaskFocusField, equals: index)
                .onAppear {
                    if subtaskCreated {
                        subtaskFocusField = index
                        subtaskCreated = false
                    }
                }
                .submitLabel(.next)
                .onSubmit {
                    if config.entity.subtasks.last == nil || !config.entity.subtasks.last!.name.isEmpty {
                        config.entity.subtasks.append(IxSubTask(name: "", completed: false))
                        subtaskCreated = true
                    }
                }
            }
            .swipeActions {
                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                    config.entity.subtasks.remove(at: index)
                }
            }
        }
    }

    // MARK: - Add Subtask Button

    var addSubtaskButton: some View {
        Button("Add subtask") {
            if config.entity.subtasks.last == nil || !config.entity.subtasks.last!.name.isEmpty {
                config.entity.subtasks.append(IxSubTask(name: "", completed: false))
                subtaskCreated = true
            }
        }
    }

    // MARK: - Connected Item Section

    var connectedItemSection: some View {
        Section {
            TaskConnectedItemSectionView(item: items.first) {
                withAnimation {
                    config.entity.itemId = nil
                }
            }
        } footer: {
            Text("This indicates that the task is connected to an item of a list, when completing this task that item will also get completed")
        }
    }
}

#Preview {
    @Previewable @State var config = EditorConfig<IxTask>()
    TaskEditor(
        config: $config
    ) {
        // on save
    }
}
