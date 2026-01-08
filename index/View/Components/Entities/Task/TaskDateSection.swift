//
//  TaskDateSection.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//

import SwiftUI
import IxCoreKit

struct TaskDateSection: View {
    @Binding var dueDate: Date?
    @Binding var reminders: [IxTaskReminder]
    @FocusState var isTaskNameFocused: Bool
    @Bindable var recurrenceState: RecurrenceState
    
    var body: some View {
        Section {
            dueDateToggle
            
            if dueDate != nil {
                dueDatePicker
            }
            
            remindersNavLink
            
            recurrenceNavLink
            
            if recurrenceState.recurrenceEnabled{
                endRecurrenceNavLink
            }
        }
    }
    
    // MARK: - Due Date Toggle
    var dueDateToggle: some View {
        Toggle(
            isOn: Binding(
                get: {
                    dueDate != nil
                },
                set: { newValue in
                    withAnimation {
                        dueDate = newValue ? Date.now : nil
                    }
                    
                    if newValue {
                        isTaskNameFocused = false
                    }
                })
        ) {
            Label {
                Text("Date")
                
                if let dueDate = dueDate {
                    Text(DateHelper.Formatters.taskDueDatePicker.string(from: dueDate))
                }
            } icon: {
                Image(systemName: "calendar")
            }
        }.labelStyle(ListLabelStyle(color: .blue))
    }
    
    // MARK: - Due Date Picker
    var dueDatePicker: some View {
        DatePicker(selection: $dueDate ?? Date.now, in: Date.now..., displayedComponents: .date) {
            Text("Select a date")
        }.datePickerStyle(.graphical)
    }
    
    // MARK: - Reminders Navigation Link
    var remindersNavLink: some View {
        NavigationLink {
            TaskRemindersView(reminders: $reminders)
        } label: {
            HStack {
                Label("Reminders", systemImage: "bell.fill")
                    .labelStyle(ListLabelStyle(color: .purple))
                
                Spacer()
                
                Text("\(reminders.count > 0 ? "\(reminders.count)" : "")")
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(dueDate == nil)
    }
    
    // MARK: - Recurrence Navigation Link
    var recurrenceNavLink: some View {
        NavigationLink(destination: {
            TaskRecurrenceView(recurrenceState: recurrenceState)
        }) {
            HStack {
                Label("Repeat", systemImage: "repeat")
                    .labelStyle(ListLabelStyle(color: .gray))
                
                Spacer()
                
                Text(recurrenceState.recurrenceEnabled ? "Enabled" : "Never")
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(dueDate == nil)
    }
    
    // MARK: - End Recurrence Navigation Link
    var endRecurrenceNavLink: some View {
        NavigationLink {
            TaskEndRecurrenceView(recurrenceState: recurrenceState)
        } label: {
            HStack {
                Text("End repeat")
                
                Spacer()
                
                Text(recurrenceState.endRepeat == .never ? "Never" : (recurrenceState.endRepeat == .onDate ? "On date" : "After..."))
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(dueDate == nil)
    }
}
