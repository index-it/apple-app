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

// MARK: Models

enum RecurrenceFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily";
    case weekly = "Weekly";
    case monthly = "Monthly";
    case yearly = "Yearly";
    
    var id: Self { self }
}

enum WeeklyFrequency: String, CaseIterable, Identifiable {
    case sunday = "Sunday";
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    
    var id: Self { self }
}

enum MonthlyWeekdayFrequency: String, CaseIterable, Identifiable {
    case first = "first";
    case second = "second";
    case third = "third";
    case fourth = "fourth";
    case fifth = "fifth";
    case last = "last";
    
    var id: Self { self }
}

enum MonthlyWeekdayFrequencyTarget: String, CaseIterable, Identifiable {
    case sunday = "Sunday";
    case monday = "Monday";
    case tuesday = "Tuesday";
    case wednesday = "Wednesday";
    case thursday = "Thursday";
    case friday = "Friday";
    case saturday = "Saturday";
    // following are not supported in EventKit?
    //    case day = "day";
    //    case weekday = "weekday";
    //    case weekendDay = "weekend day";
    
    var id: Self { self }
}

enum EndRepeat {
    case never;
    case onDate;
    case afterOccurrences;
}

// MARK: View

struct TaskFormSheet: View {
    @EnvironmentObject private var errorService: ErrorStateService
    // MARK: View props
    @Binding var showSheet: Bool
    
    @AppStorage(AppStorageKeys.loggedInUser) private var user: User?
    @State private var showPaywall = false
    
    @FocusState private var isNameFocused: Bool
    
    @State private var name: String
    @State private var description: String?
    @State private var priority: Int?
    @State private var dueDate: Date?
    @State private var rrule: String?
    @State private var reminders: [IxTaskReminder]
    @State private var itemId: String?
    @State private var subtasks: [IxSubTask]
    
    private var namePlaceholder: String
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }
    
    private var onSave: (_ name: String, _ description: String?, _ priority: Int?, _ dueDate: Date?, _ rrule: String?, _ reminders: [IxTaskReminder], _ itemId: String?, _ subtasks: [IxSubTask]) -> Void
    
    
    @FocusState private var subtaskFocusField: Int?
    @State private var isSubtasksDisclosureGroupExpanded = true
    @State private var subtaskCreated = false
    
    // MARK: Recurrence logic data
    private var monthNames: [String] = DateFormatter().shortMonthSymbols
    
    @State private var recurrenceEnabled = false
    @State private var showRecurrenceFrequencyPicker = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .daily
    @State private var showRecurrenceCountPicker = false
    @State private var recurrenceCount = 1
    @State private var weeklyFrequencies: Set<WeeklyFrequency> = Set()
    @State private var monthEachSelected = true
    @State private var monthFrequencies: Set<Int> = [1]
    @State private var monthlyWeekdayFrequency = MonthlyWeekdayFrequency.first
    @State private var monthlyWeekdayFrequencyTarget = MonthlyWeekdayFrequencyTarget.sunday
    @State private var yearFrequencies: Set<Int> = [1]
    @State private var yearDaysOfWeekSelected = false
    @State private var yearlyWeekdayFrequency = MonthlyWeekdayFrequency.first
    @State private var yearlyWeekdayFrequencyTarget = MonthlyWeekdayFrequencyTarget.sunday
    
    @State private var endRepeat = EndRepeat.never
    @State private var endRepeatDate = Date.now
    @State private var endRepeatAfterOccurrences = 30
    @State private var showEndRepeatAfterOccurrencesPicker = false
    
    @State private var showCreateReminderDaysPicker = false
    @State private var showCreateReminderTimePicker = false
    @State private var createReminderDays = 0
    @State private var createReminderTime = Date.now
    
    private var createDaysBeforeText: String {
        return createReminderDays == 0 ? "On the same day" : "\(createReminderDays) day\(createReminderDays > 1 ? "s" : "") before"
    }
    
    @Query private var items: [IxListItem]
    
    private var everyButtonValue: String {
        switch recurrenceFrequency {
        case .daily:
            if recurrenceCount == 1 {
                return "Day"
            } else {
                return "\(recurrenceCount) days"
            }
        case .weekly:
            if recurrenceCount == 1 {
                return "Week"
            } else {
                return "\(recurrenceCount) weeks"
            }
        case .monthly:
            if recurrenceCount == 1 {
                return "Month"
            } else {
                return "\(recurrenceCount) months"
            }
        case .yearly:
            if recurrenceCount == 1 {
                return "Year"
            } else {
                return "\(recurrenceCount) years"
            }
        }
    }
    
    init(
        showSheet: Binding<Bool>,
        name: String,
        description: String?,
        priority: Int?,
        dueDate: Date?,
        rrule: String?,
        reminders: [IxTaskReminder],
        itemId: String?,
        subtasks: [IxSubTask],
        namePlaceholder: String,
        onSave: @escaping (_ name: String, _ description: String?, _ priority: Int?, _ dueDate: Date?, _ rrule: String?, _ reminders: [IxTaskReminder], _ itemId: String?, _ subtasks: [IxSubTask]) -> Void
    ) {
        self._showSheet = showSheet
        
        self.name = name
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.rrule = rrule
        self.reminders = reminders
        self.itemId = itemId
        self.subtasks = subtasks
        
        self.namePlaceholder = namePlaceholder
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
        if recurrenceEnabled {
            var recurrenceWith: EKRecurrenceFrequency
            switch recurrenceFrequency {
            case .daily:
                recurrenceWith = .daily
            case .weekly:
                recurrenceWith = .weekly
            case .monthly:
                recurrenceWith = .monthly
            case .yearly:
                recurrenceWith = .yearly
            }
            
            let interval = recurrenceCount
            
            var daysOfTheWeek: [EKRecurrenceDayOfWeek]? = nil
            
            if recurrenceWith == .weekly {
                daysOfTheWeek = []
                
                weeklyFrequencies.forEach { day in
                    var weekDay: EKWeekday
                    switch day {
                    case .sunday:
                        weekDay = .sunday
                    case .monday:
                        weekDay = .monday
                    case .tuesday:
                        weekDay = .tuesday
                    case .wednesday:
                        weekDay = .wednesday
                    case .thursday:
                        weekDay = .thursday
                    case .friday:
                        weekDay = .friday
                    case .saturday:
                        weekDay = .saturday
                    }
                    
                    daysOfTheWeek!.append(EKRecurrenceDayOfWeek(weekDay))
                }
            }
            
            if recurrenceWith == .monthly && !monthEachSelected {
                daysOfTheWeek = []
                
                var weekDay: EKWeekday
                switch monthlyWeekdayFrequencyTarget {
                case .sunday:
                    weekDay = .sunday
                case .monday:
                    weekDay = .monday
                case .tuesday:
                    weekDay = .tuesday
                case .wednesday:
                    weekDay = .wednesday
                case .thursday:
                    weekDay = .thursday
                case .friday:
                    weekDay = .friday
                case .saturday:
                    weekDay = .saturday
                }
                
                var weekNumber: Int
                switch monthlyWeekdayFrequency {
                case .first:
                    weekNumber = 1
                case .second:
                    weekNumber = 2
                case .third:
                    weekNumber = 3
                case .fourth:
                    weekNumber = 4
                case .fifth:
                    weekNumber = 5
                case .last:
                    weekNumber = 6
                }
                
                daysOfTheWeek!.append(EKRecurrenceDayOfWeek(weekDay, weekNumber: weekNumber))
            }
            
            
            if recurrenceWith == .yearly && yearDaysOfWeekSelected {
                daysOfTheWeek = []
                
                var weekDay: EKWeekday
                switch yearlyWeekdayFrequencyTarget {
                case .sunday:
                    weekDay = .sunday
                case .monday:
                    weekDay = .monday
                case .tuesday:
                    weekDay = .tuesday
                case .wednesday:
                    weekDay = .wednesday
                case .thursday:
                    weekDay = .thursday
                case .friday:
                    weekDay = .friday
                case .saturday:
                    weekDay = .saturday
                }
                
                var weekNumber: Int
                switch yearlyWeekdayFrequency {
                case .first:
                    weekNumber = 1
                case .second:
                    weekNumber = 2
                case .third:
                    weekNumber = 3
                case .fourth:
                    weekNumber = 4
                case .fifth:
                    weekNumber = 5
                case .last:
                    weekNumber = 6
                }
                
                daysOfTheWeek!.append(EKRecurrenceDayOfWeek(weekDay, weekNumber: weekNumber))
            }
            
            var daysOfTheMonth: [NSNumber]? = nil
            if recurrenceWith == .monthly && monthEachSelected {
                daysOfTheMonth = Array(monthFrequencies.map({ number in
                    NSNumber(value: number)
                }))
            }
            
            var monthsOfTheYear: [NSNumber]? = nil
            if recurrenceWith == .yearly {
                monthsOfTheYear = Array(yearFrequencies.map { month in
                    NSNumber(value: month)
                })
            }
            
            var end: EKRecurrenceEnd? = nil
            if endRepeat == .onDate {
                end = EKRecurrenceEnd(end: endRepeatDate)
            }
            if endRepeat == .afterOccurrences {
                end = EKRecurrenceEnd(occurrenceCount: endRepeatAfterOccurrences)
            }
            
            let eKRecurrenceRule = EKRecurrenceRule(
                recurrenceWith: recurrenceWith,
                interval: interval,
                daysOfTheWeek: daysOfTheWeek,
                daysOfTheMonth: daysOfTheMonth,
                monthsOfTheYear: monthsOfTheYear,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: end
            )
            
            rrule = eKRecurrenceRule.description.split(separator: "RRULE").last?.trimmingCharacters(in: .whitespaces)
        } else {
            rrule = nil
        }
        
        onSave(name, description, priority, dueDate, rrule, reminders, itemId, subtasks)
        showSheet = false
    }
    
    private func parseRRule() {
        if let rrule = rrule {
            DispatchQueue.global(qos: .userInitiated).async {
                let rule = EKRecurrenceRule.recurrenceRuleFromString(rrule)
                if let rule = rule {
                    DispatchQueue.main.async {
                        recurrenceEnabled = true
                        recurrenceCount = rule.interval
                        
                        switch rule.frequency {
                        case .daily:
                            recurrenceFrequency = .daily
                        case .weekly:
                            recurrenceFrequency = .weekly
                            rule.daysOfTheWeek?.forEach { day in
                                switch day.dayOfTheWeek {
                                case .sunday:
                                    weeklyFrequencies.insert(.sunday)
                                case .monday:
                                    weeklyFrequencies.insert(.monday)
                                case .tuesday:
                                    weeklyFrequencies.insert(.tuesday)
                                case .wednesday:
                                    weeklyFrequencies.insert(.wednesday)
                                case .thursday:
                                    weeklyFrequencies.insert(.thursday)
                                case .friday:
                                    weeklyFrequencies.insert(.friday)
                                case .saturday:
                                    weeklyFrequencies.insert(.saturday)
                                }
                            }
                        case .monthly:
                            recurrenceFrequency = .monthly
                            
                            if rule.daysOfTheMonth != nil && !rule.daysOfTheMonth!.isEmpty {
                                monthFrequencies = Set(rule.daysOfTheMonth!.map { n in n.intValue })
                            } else {
                                monthEachSelected = false
                                if let dayOfWeek = rule.daysOfTheWeek?.first {
                                    switch dayOfWeek.dayOfTheWeek {
                                    case .sunday:
                                        monthlyWeekdayFrequencyTarget = .sunday
                                    case .monday:
                                        monthlyWeekdayFrequencyTarget = .monday
                                    case .tuesday:
                                        monthlyWeekdayFrequencyTarget = .tuesday
                                    case .wednesday:
                                        monthlyWeekdayFrequencyTarget = .wednesday
                                    case .thursday:
                                        monthlyWeekdayFrequencyTarget = .thursday
                                    case .friday:
                                        monthlyWeekdayFrequencyTarget = .friday
                                    case .saturday:
                                        monthlyWeekdayFrequencyTarget = .saturday
                                    }
                                    
                                    if dayOfWeek.weekNumber <= 1 {
                                        monthlyWeekdayFrequency = .first
                                    } else if dayOfWeek.weekNumber == 2 {
                                        monthlyWeekdayFrequency = .second
                                    } else if dayOfWeek.weekNumber == 3 {
                                        monthlyWeekdayFrequency = .third
                                    } else if dayOfWeek.weekNumber == 4 {
                                        monthlyWeekdayFrequency = .fourth
                                    } else if dayOfWeek.weekNumber == 5 {
                                        monthlyWeekdayFrequency = .fifth
                                    } else if dayOfWeek.weekNumber == 6 {
                                        monthlyWeekdayFrequency = .last
                                    }
                                }
                            }
                        case .yearly:
                            recurrenceFrequency = .yearly
                            
                            if rule.monthsOfTheYear != nil && !rule.monthsOfTheYear!.isEmpty {
                                yearFrequencies = Set(rule.monthsOfTheYear!.map { n in n.intValue })
                            }
                            
                            if let dayOfWeek = rule.daysOfTheWeek?.first {
                                switch dayOfWeek.dayOfTheWeek {
                                case .sunday:
                                    yearlyWeekdayFrequencyTarget = .sunday
                                case .monday:
                                    yearlyWeekdayFrequencyTarget = .monday
                                case .tuesday:
                                    yearlyWeekdayFrequencyTarget = .tuesday
                                case .wednesday:
                                    yearlyWeekdayFrequencyTarget = .wednesday
                                case .thursday:
                                    yearlyWeekdayFrequencyTarget = .thursday
                                case .friday:
                                    yearlyWeekdayFrequencyTarget = .friday
                                case .saturday:
                                    yearlyWeekdayFrequencyTarget = .saturday
                                }
                                
                                if dayOfWeek.weekNumber <= 1 {
                                    yearlyWeekdayFrequency = .first
                                } else if dayOfWeek.weekNumber == 2 {
                                    yearlyWeekdayFrequency = .second
                                } else if dayOfWeek.weekNumber == 3 {
                                    yearlyWeekdayFrequency = .third
                                } else if dayOfWeek.weekNumber == 4 {
                                    yearlyWeekdayFrequency = .fourth
                                } else if dayOfWeek.weekNumber == 5 {
                                    yearlyWeekdayFrequency = .fifth
                                } else if dayOfWeek.weekNumber == 6 {
                                    yearlyWeekdayFrequency = .last
                                }
                            }
                        
                        if let end = rule.recurrenceEnd {
                            if let endDate = end.endDate {
                                endRepeat = .onDate
                                endRepeatDate = endDate
                            } else {
                                endRepeatAfterOccurrences = end.occurrenceCount
                            }
                        }
                    }
                }
            }
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
    
    var body: some View {
        NavigationView {
            Form {
                nameAndDescriptionSection
                
                prioritySection
                
                subtasksSection
                
                dueDateSection
                
                
                if itemId != nil {
                    connectedItemSection
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showSheet = false
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
            
            parseRRule()
        }
        .paywallCover(isPresented: $showPaywall)
    }
    
    // Name and Description Section
    var nameAndDescriptionSection: some View {
        Section {
            TextField("Name", text: $name)
                .focused($isNameFocused)
            
            TextField("Description", text: $description ?? "", axis: .vertical)
        }
    }
    
    // Priority Section
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
    
    // Due Date Section
    var dueDateSection: some View {
        Section {
            dueDateToggle
            
            if dueDate != nil {
                dueDatePicker
            }
            
            remindersNavLink
            
            recurrenceNavLink
            
            if recurrenceEnabled {
                endRecurrenceNavLink
            }
        }
    }
    
    // Due Date Toggle
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
                        isNameFocused = false
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
        }.labelStyle(ColorfulIconLabelStyle(color: .blue))
    }
    
    // Due Date Picker
    var dueDatePicker: some View {
        DatePicker(selection: $dueDate ?? Date.now, in: Date.now..., displayedComponents: .date) {
            Text("Select a date")
        }.datePickerStyle(.graphical)
    }
    
    // Reminders Navigation Link
    var remindersNavLink: some View {
        NavigationLink {
            remindersView
        } label: {
            HStack {
                Label("Reminders", systemImage: "bell.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .purple))
                
                Spacer()
                
                Text("\(reminders.count > 0 ? "\(reminders.count)" : "")")
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(dueDate == nil)
    }
    
    // Reminders View
    var remindersView: some View {
        Form {
            if !reminders.isEmpty {
                existingRemindersSection
            }
            
            createReminderSection
        }.navigationTitle("Reminders")
    }
    
    // Existing Reminders Section
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
    
    // Create Reminder Section
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
    
    // Create Reminder Days Picker
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
    
    // Create Reminder Time Picker
    var createReminderTimePicker: some View {
        DatePicker("At time", selection: $createReminderTime, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
    }
    
    // Add Reminder Button
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
    
    // Recurrence Navigation Link
    var recurrenceNavLink: some View {
        NavigationLink(destination: {
            recurrenceView
        }) {
            HStack {
                Label("Repeat", systemImage: "repeat")
                    .labelStyle(ColorfulIconLabelStyle(color: .gray))
                
                Spacer()
                
                Text(recurrenceEnabled ? "Enabled" : "Never")
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(dueDate == nil)
    }
    
    // Recurrence View
    var recurrenceView: some View {
        Form {
            Section {
                Toggle("Enable repeat", isOn: $recurrenceEnabled)
            }
            
            recurrenceFrequencySection
            
            if recurrenceFrequency == .weekly && recurrenceEnabled {
                weeklyRecurrenceSection
            }
            
            if recurrenceFrequency == .monthly && recurrenceEnabled {
                monthlyRecurrenceSection
            }
            
            if recurrenceFrequency == .yearly && recurrenceEnabled {
                yearlyRecurrenceSection
            }
        }.navigationTitle("Repeat")
    }
    
    // Recurrence Frequency Section
    var recurrenceFrequencySection: some View {
        Section {
            Button {
                withAnimation {
                    showRecurrenceFrequencyPicker = !showRecurrenceFrequencyPicker
                    showRecurrenceCountPicker = false
                }
            } label: {
                HStack {
                    Text("Frequency")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    Text(recurrenceFrequency.rawValue)
                        .foregroundStyle(showRecurrenceFrequencyPicker ? .accentColor : UIColor.label.toColor())
                }.opacity(recurrenceEnabled ? 1 : 0.4)
            }.disabled(!recurrenceEnabled)
            
            if showRecurrenceFrequencyPicker {
                Picker("Frequency", selection: $recurrenceFrequency) {
                    ForEach(RecurrenceFrequency.allCases) { frequency in
                        Text(frequency.rawValue)
                            .tag(frequency)
                    }
                }.pickerStyle(.wheel)
            }
            
            Button {
                withAnimation {
                    if !showRecurrenceCountPicker {
                        showRecurrenceFrequencyPicker = false
                    }
                    
                    showRecurrenceCountPicker = !showRecurrenceCountPicker
                }
            } label: {
                HStack {
                    Text("Every")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    Text(everyButtonValue)
                        .foregroundStyle(showRecurrenceCountPicker ? .accentColor : UIColor.label.toColor())
                }.opacity(recurrenceEnabled ? 1 : 0.4)
            }.disabled(!recurrenceEnabled)
            
            
            if showRecurrenceCountPicker {
                Picker("Count", selection: $recurrenceCount) {
                    ForEach(1...999, id: \.self) { day in
                        HStack {
                            Text("\(day)")
                                .tag(day)
                        }
                    }
                }.pickerStyle(.wheel)
            }
        }
    }
    
    // Weekly Recurrence Section
    var weeklyRecurrenceSection: some View {
        Section {
            ForEach(WeeklyFrequency.allCases) { weeklyFrequency in
                Button {
                    if weeklyFrequencies.contains(weeklyFrequency) {
                        weeklyFrequencies.remove(weeklyFrequency)
                    } else {
                        weeklyFrequencies.insert(weeklyFrequency)
                    }
                } label: {
                    HStack {
                        Text(weeklyFrequency.rawValue)
                            .foregroundStyle(UIColor.label.toColor())
                        Spacer()
                        if weeklyFrequencies.contains(weeklyFrequency) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }
    
    // Monthly Recurrence Section
    var monthlyRecurrenceSection: some View {
        Section {
            monthlyTypeSelectionButtons
            
            if monthEachSelected {
                monthlyDaysGrid
            } else {
                monthlyWeekdayPickers
            }
        }
    }
    
    // Monthly Type Selection Buttons
    var monthlyTypeSelectionButtons: some View {
        Group {
            Button {
                withAnimation {
                    monthEachSelected = true
                }
            } label: {
                HStack {
                    Text("Each")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    if monthEachSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            Button {
                withAnimation {
                    monthEachSelected = false
                }
            } label: {
                HStack {
                    Text("On the...")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    if !monthEachSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    // Monthly Days Grid
    var monthlyDaysGrid: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                ForEach(1...7, id: \.self) { day in
                    monthDayCell(day)
                }
            }
            GridRow {
                ForEach(8...14, id: \.self) { day in
                    monthDayCell(day)
                }
            }
            GridRow {
                ForEach(15...21, id: \.self) { day in
                    monthDayCell(day)
                }
            }
            GridRow {
                ForEach(22...28, id: \.self) { day in
                    monthDayCell(day)
                }
            }
            
            GridRow {
                ForEach(29...31, id: \.self) { day in
                    monthDayCell(day)
                }
            }
        }.frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .listRowBackground(UIColor.systemGroupedBackground.toColor())
    }
    
    // Month Day Cell (helper function for grid)
    func monthDayCell(_ day: Int) -> some View {
        Group {
            if monthFrequencies.contains(day) {
                Color.accentColor
                    .overlay {
                        Text("\(day)")
                            .foregroundStyle(UIColor.systemBackground.toColor())
                    }
                
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
            } else {
                UIColor.systemBackground.toColor()
                    .overlay {
                        Text("\(day)")
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
            }
        }.onTapGesture {
            withAnimation {
                if monthFrequencies.contains(day) && monthFrequencies.count > 1 {
                    monthFrequencies.remove(day)
                } else {
                    monthFrequencies.insert(day)
                }
            }
        }
    }
    
    // Monthly Weekday Pickers
    var monthlyWeekdayPickers: some View {
        HStack(spacing: 0) {
            Picker("frequency", selection: $monthlyWeekdayFrequency) {
                ForEach(MonthlyWeekdayFrequency.allCases) { freq in
                    Text(freq.rawValue)
                        .tag(freq)
                }
            }.pickerStyle(.wheel)
            
            Picker("frequency target", selection: $monthlyWeekdayFrequencyTarget) {
                ForEach(MonthlyWeekdayFrequencyTarget.allCases) { target in
                    Text(target.rawValue)
                        .tag(target)
                }
            }.pickerStyle(.wheel)
        }
    }
    
    // Yearly Recurrence Section
    var yearlyRecurrenceSection: some View {
        Group {
            Section {
                yearlyMonthsGrid
            }
            
            Section {
                yearlyWeekdaySelectionSection
            }
        }
    }
    
    // Yearly Months Grid
    var yearlyMonthsGrid: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            ForEach(0...2, id: \.self) { row in
                GridRow {
                    ForEach(1...4, id: \.self) { tMonth in
                        let month = (row * 4) + tMonth
                        yearMonthCell(month)
                    }
                }
            }
        }.listRowInsets(EdgeInsets())
            .listRowBackground(UIColor.systemGroupedBackground.toColor())
    }
    
    // Year Month Cell (helper function for grid)
    func yearMonthCell(_ month: Int) -> some View {
        Group {
            if yearFrequencies.contains(month) {
                Color.accentColor
                    .overlay {
                        Text(monthNames[month - 1])
                            .foregroundStyle(UIColor.systemBackground.toColor())
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
            } else {
                UIColor.systemBackground.toColor()
                    .overlay {
                        Text(monthNames[month - 1])
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }.onTapGesture {
            withAnimation {
                if yearFrequencies.contains(month) && yearFrequencies.count > 1 {
                    yearFrequencies.remove(month)
                } else {
                    yearFrequencies.insert(month)
                }
            }
        }
    }
    
    // Yearly Weekday Selection Section
    var yearlyWeekdaySelectionSection: some View {
        Group {
            Toggle("Days of Week", isOn: $yearDaysOfWeekSelected)
            
            if yearDaysOfWeekSelected {
                HStack(spacing: 0) {
                    Picker("frequency", selection: $yearlyWeekdayFrequency) {
                        ForEach(MonthlyWeekdayFrequency.allCases) { freq in
                            Text(freq.rawValue)
                                .tag(freq)
                        }
                    }.pickerStyle(.wheel)
                    
                    Picker("frequency target", selection: $yearlyWeekdayFrequencyTarget) {
                        ForEach(MonthlyWeekdayFrequencyTarget.allCases) { target in
                            Text(target.rawValue)
                                .tag(target)
                        }
                    }.pickerStyle(.wheel)
                }
            }
        }
    }
    
    // End Recurrence Navigation Link
    var endRecurrenceNavLink: some View {
        NavigationLink {
            endRecurrenceView
        } label: {
            HStack {
                Text("End repeat")
                
                Spacer()
                
                Text(endRepeat == .never ? "Never" : (endRepeat == .onDate ? "On date" : "After..."))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // End Recurrence View
    var endRecurrenceView: some View {
        Form {
            Section {
                endRepeatNeverButton
                
                endRepeatOnDateButton
                
                if endRepeat == .onDate {
                    endRepeatDatePicker
                }
                
                endRepeatAfterOccurrencesButton
                
                if showEndRepeatAfterOccurrencesPicker {
                    endRepeatOccurrencesPicker
                }
            }
        }.navigationTitle("End repeat")
    }
    
    // End Repeat Never Button
    var endRepeatNeverButton: some View {
        Button {
            withAnimation {
                endRepeat = .never
            }
        } label: {
            HStack {
                Text("Repeat Forever")
                    .foregroundStyle(UIColor.label.toColor())
                Spacer()
                if endRepeat == .never {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    // End Repeat On Date Button
    var endRepeatOnDateButton: some View {
        Button {
            withAnimation {
                endRepeat = .onDate
            }
        } label: {
            HStack {
                Text("End Repeat Date")
                    .foregroundStyle(UIColor.label.toColor())
                Spacer()
                if endRepeat == .onDate {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    // End Repeat Date Picker
    var endRepeatDatePicker: some View {
        DatePicker(selection: $endRepeatDate, in: Date.now..., displayedComponents: .date) {
            Text("Select a date")
        }.datePickerStyle(.graphical)
    }
    
    // End Repeat After Occurrences Button
    var endRepeatAfterOccurrencesButton: some View {
        Button {
            withAnimation {
                endRepeat = .afterOccurrences
                
                if !showEndRepeatAfterOccurrencesPicker {
                    showEndRepeatAfterOccurrencesPicker = true
                }
            }
        } label: {
            HStack {
                Text("After")
                    .foregroundStyle(UIColor.label.toColor())
                Spacer()
                Text("\(endRepeatAfterOccurrences) occurrence\(endRepeatAfterOccurrences > 1 ? "s" : "")")
                    .foregroundStyle(endRepeat == .afterOccurrences ? .accentColor : UIColor.label.toColor())
            }
        }
    }
    
    // End Repeat Occurrences Picker
    var endRepeatOccurrencesPicker: some View {
        Picker("Count", selection: $endRepeatAfterOccurrences) {
            ForEach(1...999, id: \.self) { occurrence in
                HStack {
                    Text("\(occurrence)")
                        .tag(occurrence)
                }
            }
        }.pickerStyle(.wheel)
    }
    
    // Subtasks Section
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
    
    // Subtasks List
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
    
    // Add Subtask Button
    var addSubtaskButton: some View {
        Button("Add subtask") {
            if subtasks.last == nil || !subtasks.last!.name.isEmpty {
                subtasks.append(IxSubTask(name: "", completed: false))
                subtaskCreated = true
            }
        }
    }
    
    // Connected Item Section
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
    TaskFormSheet(
        showSheet: .constant(true),
        name: "",
        description: nil,
        priority: nil,
        dueDate: nil,
        rrule: nil,
        reminders: [],
        itemId: nil,
        subtasks: [],
        namePlaceholder: "Enter task name",
        onSave: { name, description, priority, dueDate, rrule, reminders, itemId, subtasks in
            // Handle saving the task here
            print("Task saved: \(name)")
        }
    )
}
