//
//  TaskEditorSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI
import SwiftData
import EventKit
import IxCoreKit


struct TaskEditor: View {
    @EnvironmentObject private var errorService: ErrorStateService
    // MARK: View props
    @Binding var isPresented: Bool
    private var addingNew: Bool
    
    @FocusState private var isNameFocused: Bool
    
    @State private var name: String
    @State private var description: String?
    @State private var priority: Int?
    @State private var dueDate: Date?
    @State private var rrule: String?
    @State private var reminders: [IxTaskReminder]
    @State private var itemId: String?
    @State private var subtasks: [IxSubTask]
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }
    
    private var onSave: (_ name: String, _ description: String?, _ priority: Int?, _ dueDate: Date?, _ rrule: String?, _ reminders: [IxTaskReminder], _ itemId: String?, _ subtasks: [IxSubTask]) -> Void
    
    @FocusState private var subtaskFocusField: Int?
    @State private var isSubtasksDisclosureGroupExpanded = true
    @State private var subtaskCreated = false
    
    @State private var recurrenceState = RecurrenceState()
    
    @Query private var items: [IxListItem]
    
    init(
        isPresented: Binding<Bool>,
        addingNew: Bool = true,
        name: String,
        description: String?,
        priority: Int?,
        dueDate: Date?,
        rrule: String?,
        reminders: [IxTaskReminder],
        itemId: String?,
        subtasks: [IxSubTask],
        onSave: @escaping (_ name: String, _ description: String?, _ priority: Int?, _ dueDate: Date?, _ rrule: String?, _ reminders: [IxTaskReminder], _ itemId: String?, _ subtasks: [IxSubTask]) -> Void
    ) {
        self._isPresented = isPresented
        self.addingNew = addingNew
        
        self.name = name
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.rrule = rrule
        self.reminders = reminders
        self.itemId = itemId
        self.subtasks = subtasks
        
        self.onSave = onSave
        
        // MARK: item query
        var itemDescription: FetchDescriptor<IxListItem>
        
        if let itemId = itemId {
            itemDescription = FetchDescriptor<IxListItem> (
                predicate: #Predicate { item in
                    item.id == itemId
                }
            )
        } else {
            itemDescription = FetchDescriptor<IxListItem> (
                predicate: #Predicate { _ in false }
            )
        }
        
        itemDescription.fetchLimit = 1
        _items = Query(itemDescription)
    }
    
    private func onSaveSubmit() {
        rrule = recurrenceState.generateRRule()
        
        onSave(name, description, priority, dueDate, rrule, reminders, itemId, subtasks)
        isPresented = false
    }
    
    var body: some View {
        NavigationView {
            Form {
                nameAndDescriptionSection
                
                prioritySection
                
                subtasksSection
                
                TaskDateSection(
                    dueDate: $dueDate,
                    reminders: $reminders,
                    isTaskNameFocused: _isNameFocused,
                    recurrenceState: recurrenceState
                )
                
                if itemId != nil {
                    connectedItemSection
                }
            }
            .navigationTitle(addingNew ? "Add Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSaveSubmit()
                    }
                    .disabled(isNameInvalid)
                }
            }
        }
        .onAppear {
            if name.isEmpty {
                isNameFocused = true
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                recurrenceState.parseRRule(rrule)
            }
        }
    }
    
    // MARK: - Name and Description Section
    var nameAndDescriptionSection: some View {
        Section {
            TextField("Name", text: $name)
                .focused($isNameFocused)
            
            TextField("Description", text: $description ?? "", axis: .vertical)
        }
    }
    
    // MARK: - Priority Section
    var prioritySection: some View {
        Picker("Priority", systemImage: "flag.fill", selection: $priority) {
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
        }.labelStyle(ColorfulIconLabelStyle(color: .red))
    }
    
    // MARK: - Subtasks Section
    var subtasksSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isSubtasksDisclosureGroupExpanded) {
                subtasksList
                
                addSubtaskButton
            } label: {
                Label("Subtasks", systemImage: "checklist.unchecked")
                    .labelStyle(ColorfulIconLabelStyle(color: .brown))
            }
            
        } header: {
            Text("Subtasks")
        }
    }
    
    // MARK: - Subtasks List
    var subtasksList: some View {
        ForEach(Array(subtasks.enumerated()), id: \.offset) { index, subtask in
            HStack {
                Button {
                    subtasks[index].completed = !subtask.completed
                } label: {
                    Image(systemName: subtask.completed ? "inset.filled.circle" : "circle")
                }
                
                TextField(
                    "Insert name",
                    text: $subtasks[index].name
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
                    if subtasks.last == nil || !subtasks.last!.name.isEmpty {
                        subtasks.append(IxSubTask(name: "", completed: false))
                        subtaskCreated = true
                    }
                }
            }
            .swipeActions {
                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                    subtasks.remove(at: index)
                }
            }
        }
    }
    
    // MARK: - Add Subtask Button
    var addSubtaskButton: some View {
        Button("Add subtask") {
            if subtasks.last == nil || !subtasks.last!.name.isEmpty {
                subtasks.append(IxSubTask(name: "", completed: false))
                subtaskCreated = true
            }
        }
    }
    
    // MARK: - Connected Item Section
    var connectedItemSection: some View {
        Section {
            TaskConnectedItemSectionView(item: items.first) {
                withAnimation {
                    itemId = nil
                }
            }
        } footer: {
            Text("This indicates that the task is connected to an item of a list, when completing this task that item will also get completed")
        }
    }
}

#Preview {
    TaskEditor(
        isPresented: .constant(true),
        name: "",
        description: nil,
        priority: nil,
        dueDate: nil,
        rrule: nil,
        reminders: [],
        itemId: nil,
        subtasks: [],
        onSave: { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
            // Handle saving the task here
            print("Task saved: \(name)")
        }
    )
}
