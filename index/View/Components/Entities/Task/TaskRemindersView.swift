//
//  TaskRemindersView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//


//
//  TaskRemindersView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//

import SwiftUI
import IxCoreKit

struct TaskRemindersView: View {
    @EnvironmentObject private var errorService: ErrorStateService
    @AppStorage(AppStorageKeys.loggedInUser) private var user: User?
    
    @Binding var reminders: [IxTaskReminder]
    @State private var showPaywall = false
    
    @State private var showCreateReminderDaysPicker = false
    @State private var showCreateReminderTimePicker = false
    @State private var createReminderDays = 0
    @State private var createReminderTime = Date.now
    
    private var createDaysBeforeText: String {
        return createReminderDays == 0 ? "On the same day" : "\(createReminderDays) day\(createReminderDays > 1 ? "s" : "") before"
    }
    
    var body: some View {
        Form {
            if !reminders.isEmpty {
                existingRemindersSection
            }
            
            createReminderSection
        }
        .navigationTitle("Reminders")
        .paywallCover(isPresented: $showPaywall)
    }
    
    // MARK: - Existing Reminders Section
    var existingRemindersSection: some View {
        Section {
            ForEach(Array(reminders.enumerated()), id: \.offset) { index, reminder in
                let dayText = reminder.daysBefore == 0 ? "On the same day" : "\(reminder.daysBefore) day\(reminder.daysBefore > 1 ? "s" : "") before"
                
                Text("\(dayText) at \(reminder.hourAndMinuteString())")
                    .swipeActions(allowsFullSwipe: true) {
                        Button("Delete", systemImage: "trash.fill", role: .destructive) {
                            reminders.remove(at: index)
                        }
                    }
            }
        } header: {
            Text("Active reminders")
        } footer: {
            Text("Swipe left to delete a reminder")
        }
    }
    
    // MARK: - Create Reminder Section
    var createReminderSection: some View {
        Section {
            Button {
                withAnimation {
                    showCreateReminderDaysPicker = !showCreateReminderDaysPicker
                    showCreateReminderTimePicker = false
                }
            } label: {
                HStack {
                    Text("Date")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    Text(createDaysBeforeText)
                        .foregroundStyle(showCreateReminderDaysPicker ? .accentColor : UIColor.label.toColor())
                }
            }
            
            if showCreateReminderDaysPicker {
                createReminderDaysPicker
            }
            
            Button {
                withAnimation {
                    showCreateReminderTimePicker = !showCreateReminderTimePicker
                    showCreateReminderDaysPicker = false
                }
            } label: {
                HStack {
                    Text("At time")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    Text(createReminderTime.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(showCreateReminderTimePicker ? .accentColor : UIColor.label.toColor())
                }
            }
            
            if showCreateReminderTimePicker {
                createReminderTimePicker
            }
            
            addReminderButton
        }
    }
    
    // MARK: - Create Reminder Days Picker
    var createReminderDaysPicker: some View {
        Picker("Days before", selection: $createReminderDays) {
            ForEach(RecurrenceFrequency.allCases) { frequency in
                ForEach(0...999, id: \.self) { days in
                    HStack {
                        Text("\(days)")
                            .tag(days)
                    }
                }
            }
        }
        .pickerStyle(.wheel)
    }
    
    // MARK: - Create Reminder Time Picker
    var createReminderTimePicker: some View {
        DatePicker("At time", selection: $createReminderTime, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
    }
    
    // MARK: - Add Reminder Button
    var addReminderButton: some View {
        Button {
            Task {
                if !NotificationManager.shared.hasPermissions() {
                    let accepted = await NotificationManager.shared.request()
                    if accepted {
                        addReminder()
                    } else {
                        errorService.insert(.customMessage(title: "Enable notifications", message: "Go into Settings > Apps > Index and enable notifications to use task reminders."))
                    }
                } else {
                    addReminder()
                }
            }
        } label: {
            Text("Add reminder")
                .frame(maxWidth: .infinity)
        }
    }
    
    func addReminder() {
        if !reminders.isEmpty && user?.has_pro != true {
            showPaywall = true
        } else {
            let timeOffset = (Calendar.current.component(.hour, from: createReminderTime) * 60 * 60 * 1000) + (Calendar.current.component(.minute, from: createReminderTime) * 60 * 1000)
            
            reminders.append(
                IxTaskReminder(
                    daysBefore: Int64(createReminderDays),
                    timeOffset: Int64(DateHelper.reminderOffsetToUtc(Int64(timeOffset)))
                )
            )
        }
    }
}