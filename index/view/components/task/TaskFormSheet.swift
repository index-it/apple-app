//
//  TaskFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import SwiftUI

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
    case day = "day";
    case weekday = "weekday";
    case weekendDay = "weekend day";
    
    var id: Self { self }
}

enum EndRepeat {
    case never;
    case onDate;
    case afterOccurrences;
}

struct TaskFormSheet: View {
    @Binding var showSheet: Bool
    
    @FocusState private var isNameFocused: Bool
    
    @State private var name: String
    @State private var description: String?
    @State private var priority: Int?
    @State private var dueDate: Date?
    @State private var rrule: String?
    @State private var reminders: [IxTaskReminder]
    @State private var itemId: String?
    @State private var subtasks: [IxSubTask]
    
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
    
    
    private var namePlaceholder: String
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }
    
    private var onSave: (_ name: String, _ description: String?, _ priority: Int?, _ dueDate: Date?, _ rrule: String?, _ reminders: [IxTaskReminder], _ itemId: String?, _ subtasks: [IxSubTask]) -> Void
    
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
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Name", text: $name)
                            .focused($isNameFocused)
                        
                        TextField("Description", text: $description ?? "")
                            .focused($isNameFocused)
                    }
                    
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
                    
                    Section {
                        Toggle(
                            isOn: Binding(
                                get: {
                                    dueDate != nil
                                },
                                set: { newValue in
                                    withAnimation {
                                        dueDate = newValue ? Date.now : nil
                                    }
                                })
                        ) {
                            Label {
                                Text("Date")
                                
                                if let dueDate = dueDate {
                                    Text(IxDateUtils.Formatters.shared.taskDueDatePicker.string(from: dueDate))
                                }
                            } icon: {
                                Image(systemName: "calendar")
                            }
                        }.labelStyle(ColorfulIconLabelStyle(color: .blue))
                        
                        if dueDate != nil {
                            DatePicker(selection: $dueDate ?? Date.now, in: Date.now..., displayedComponents: .date) {
                                Text("Select a date")
                            }.datePickerStyle(.graphical)
                        }
                        
                        NavigationLink {
                            Button("Hello") {}
                        } label: {
                            Label("Reminders", systemImage: "bell.fill")
                                .labelStyle(ColorfulIconLabelStyle(color: .purple))
                        }.disabled(dueDate == nil)
                        
                        NavigationLink(destination: {
                            Form {
                                Section {
                                    Toggle("Enable repeat", isOn: $recurrenceEnabled)
                                }
                                
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
                                
                                if recurrenceFrequency == .weekly {
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
                                
                                if recurrenceFrequency == .monthly {
                                    Section {
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
                                        
                                        if monthEachSelected {
                                            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                                                GridRow {
                                                    ForEach(1...7, id: \.self) { day in
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
                                                }
                                                GridRow {
                                                    ForEach(8...14, id: \.self) { day in
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
                                                }
                                                GridRow {
                                                    ForEach(15...21, id: \.self) { day in
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
                                                }
                                                GridRow {
                                                    ForEach(22...28, id: \.self) { day in
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
                                                }
                                                
                                                GridRow {
                                                    ForEach(29...31, id: \.self) { day in
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
                                                }
                                            }.frame(maxWidth: .infinity)
                                                .listRowInsets(EdgeInsets())
                                                .listRowBackground(UIColor.systemGroupedBackground.toColor())
                                        } else {
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
                                    }
                                }
                                if recurrenceFrequency == .yearly {
                                    Section {
                                        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                                            ForEach(0...2, id: \.self) { row in
                                                GridRow {
                                                    ForEach(1...4, id: \.self) { tMonth in
                                                        let month = (row * 4) + tMonth
                                                        
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
                                                }
                                            }
                                        }.listRowInsets(EdgeInsets())
                                            .listRowBackground(UIColor.systemGroupedBackground.toColor())
                                        
                                    }
                                    
                                    Section {
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
                            }.navigationTitle("Repeat")
                        }) {
                            HStack {
                                Label("Repeat", systemImage: "repeat")
                                    .labelStyle(ColorfulIconLabelStyle(color: .gray))
                                
                                Spacer()
                                
                                Text(recurrenceEnabled ? "TODO" : "Never")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(dueDate == nil)
                        
                        if recurrenceEnabled {
                            NavigationLink {
                                Form {
                                    Section {
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
                                        
                                        if endRepeat == .onDate {
                                            DatePicker(selection: $endRepeatDate, in: Date.now..., displayedComponents: .date) {
                                                Text("Select a date")
                                            }.datePickerStyle(.graphical)
                                        }
                                        
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
                                        
                                        if showEndRepeatAfterOccurrencesPicker {
                                            Picker("Count", selection: $endRepeatAfterOccurrences) {
                                                ForEach(1...999, id: \.self) { occurrence in
                                                    HStack {
                                                        Text("\(occurrence)")
                                                            .tag(occurrence)
                                                    }
                                                }
                                            }.pickerStyle(.wheel)
                                        }
                                    }
                                }.navigationTitle("End repeat")
                            } label: {
                                HStack {
                                    Text("End repeat")
                                    
                                    Spacer()
                                    
                                    Text(endRepeat == .never ? "Never" : "TODO")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        

                    }
                    
                    NavigationLink(destination: {
                        Button("Hello") {}
                    }) {
                        Label("Subtasks", systemImage: "checklist.unchecked")
                            .labelStyle(ColorfulIconLabelStyle(color: .brown))
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
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
                        //                        onSave
                        showSheet = false
                    }
                    .disabled(isNameInvalid)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
}

#Preview {
    TaskFormSheet(
        showSheet: .constant(false),
        name: "",
        description: nil,
        priority: nil,
        dueDate: nil,
        rrule: nil,
        reminders: [],
        itemId: nil,
        subtasks: [],
        namePlaceholder: "Enter task name",
        onSave: { _, _, _, _, _, _, _, _ in }
    )
}
