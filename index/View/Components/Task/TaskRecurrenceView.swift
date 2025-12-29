//
//  TaskRecurrenceView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//


//
//  TaskRecurrenceView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//

import SwiftUI

struct TaskRecurrenceView: View {
    @Bindable var recurrenceState: RecurrenceState
    
    var monthNames: [String] = DateFormatter().shortMonthSymbols
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable repeat", isOn: $recurrenceState.recurrenceEnabled)
            }
            
            recurrenceFrequencySection
            
            if recurrenceState.recurrenceFrequency == .weekly && recurrenceState.recurrenceEnabled {
                weeklyRecurrenceSection
            }
            
            if recurrenceState.recurrenceFrequency == .monthly && recurrenceState.recurrenceEnabled {
                monthlyRecurrenceSection
            }
            
            if recurrenceState.recurrenceFrequency == .yearly && recurrenceState.recurrenceEnabled {
                yearlyRecurrenceSection
            }
        }
        .navigationTitle("Repeat")
    }
    
    // MARK: - Recurrence Frequency Section
    var recurrenceFrequencySection: some View {
        Section {
            Button {
                withAnimation {
                    recurrenceState.showRecurrenceFrequencyPicker = !recurrenceState.showRecurrenceFrequencyPicker
                    recurrenceState.showRecurrenceCountPicker = false
                }
            } label: {
                HStack {
                    Text("Frequency")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    Text(recurrenceState.recurrenceFrequency.rawValue)
                        .foregroundStyle(recurrenceState.showRecurrenceFrequencyPicker ? .accentColor : UIColor.label.toColor())
                }.opacity(recurrenceState.recurrenceEnabled ? 1 : 0.4)
            }.disabled(!recurrenceState.recurrenceEnabled)
            
            if recurrenceState.showRecurrenceFrequencyPicker {
                Picker("Frequency", selection: $recurrenceState.recurrenceFrequency) {
                    ForEach(RecurrenceFrequency.allCases) { frequency in
                        Text(frequency.rawValue)
                            .tag(frequency)
                    }
                }.pickerStyle(.wheel)
            }
            
            Button {
                withAnimation {
                    if !recurrenceState.showRecurrenceCountPicker {
                        recurrenceState.showRecurrenceFrequencyPicker = false
                    }
                    
                    recurrenceState.showRecurrenceCountPicker = !recurrenceState.showRecurrenceCountPicker
                }
            } label: {
                HStack {
                    Text("Every")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    Text(recurrenceState.everyButtonValue)
                        .foregroundStyle(recurrenceState.showRecurrenceCountPicker ? .accentColor : UIColor.label.toColor())
                }.opacity(recurrenceState.recurrenceEnabled ? 1 : 0.4)
            }.disabled(!recurrenceState.recurrenceEnabled)
            
            
            if recurrenceState.showRecurrenceCountPicker {
                Picker("Count", selection: $recurrenceState.recurrenceCount) {
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
    
    // MARK: - Weekly Recurrence Section
    var weeklyRecurrenceSection: some View {
        Section {
            ForEach(WeeklyFrequency.allCases) { weeklyFrequency in
                Button {
                    if recurrenceState.weeklyFrequencies.contains(weeklyFrequency) {
                        recurrenceState.weeklyFrequencies.remove(weeklyFrequency)
                    } else {
                        recurrenceState.weeklyFrequencies.insert(weeklyFrequency)
                    }
                } label: {
                    HStack {
                        Text(weeklyFrequency.rawValue)
                            .foregroundStyle(UIColor.label.toColor())
                        Spacer()
                        if recurrenceState.weeklyFrequencies.contains(weeklyFrequency) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Monthly Recurrence Section
    var monthlyRecurrenceSection: some View {
        Section {
            monthlyTypeSelectionButtons
            
            if recurrenceState.monthEachSelected {
                monthlyDaysGrid
            } else {
                monthlyWeekdayPickers
            }
        }
    }
    
    // MARK: - Monthly Type Selection Buttons
    var monthlyTypeSelectionButtons: some View {
        Group {
            Button {
                withAnimation {
                    recurrenceState.monthEachSelected = true
                }
            } label: {
                HStack {
                    Text("Each")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    if recurrenceState.monthEachSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            Button {
                withAnimation {
                    recurrenceState.monthEachSelected = false
                }
            } label: {
                HStack {
                    Text("On the...")
                        .foregroundStyle(UIColor.label.toColor())
                    Spacer()
                    if !recurrenceState.monthEachSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Monthly Days Grid
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
    
    // MARK: - Month Day Cell
    func monthDayCell(_ day: Int) -> some View {
        Group {
            if recurrenceState.monthFrequencies.contains(day) {
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
                if recurrenceState.monthFrequencies.contains(day) && recurrenceState.monthFrequencies.count > 1 {
                    recurrenceState.monthFrequencies.remove(day)
                } else {
                    recurrenceState.monthFrequencies.insert(day)
                }
            }
        }
    }
    
    // MARK: - Monthly Weekday Pickers
    var monthlyWeekdayPickers: some View {
        HStack(spacing: 0) {
            Picker("frequency", selection: $recurrenceState.monthlyWeekdayFrequency) {
                ForEach(MonthlyWeekdayFrequency.allCases) { freq in
                    Text(freq.rawValue)
                        .tag(freq)
                }
            }.pickerStyle(.wheel)
            
            Picker("frequency target", selection: $recurrenceState.monthlyWeekdayFrequencyTarget) {
                ForEach(MonthlyWeekdayFrequencyTarget.allCases) { target in
                    Text(target.rawValue)
                        .tag(target)
                }
            }.pickerStyle(.wheel)
        }
    }
    
    // MARK: - Yearly Recurrence Section
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
    
    // MARK: - Yearly Months Grid
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
    
    // MARK: - Year Month Cell
    func yearMonthCell(_ month: Int) -> some View {
        Group {
            if recurrenceState.yearFrequencies.contains(month) {
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
                if recurrenceState.yearFrequencies.contains(month) && recurrenceState.yearFrequencies.count > 1 {
                    recurrenceState.yearFrequencies.remove(month)
                } else {
                    recurrenceState.yearFrequencies.insert(month)
                }
            }
        }
    }
    
    // MARK: - Yearly Weekday Selection Section
    var yearlyWeekdaySelectionSection: some View {
        Group {
            Toggle("Days of Week", isOn: $recurrenceState.yearDaysOfWeekSelected)
            
            if recurrenceState.yearDaysOfWeekSelected {
                HStack(spacing: 0) {
                    Picker("frequency", selection: $recurrenceState.yearlyWeekdayFrequency) {
                        ForEach(MonthlyWeekdayFrequency.allCases) { freq in
                            Text(freq.rawValue)
                                .tag(freq)
                        }
                    }.pickerStyle(.wheel)
                    
                    Picker("frequency target", selection: $recurrenceState.yearlyWeekdayFrequencyTarget) {
                        ForEach(MonthlyWeekdayFrequencyTarget.allCases) { target in
                            Text(target.rawValue)
                                .tag(target)
                        }
                    }.pickerStyle(.wheel)
                }
            }
        }
    }
}

struct TaskEndRecurrenceView: View {
    @Bindable var recurrenceState: RecurrenceState
    
    var body: some View {
        Form {
            Section {
                endRepeatNeverButton
                
                endRepeatOnDateButton
                
                if recurrenceState.endRepeat == .onDate {
                    endRepeatDatePicker
                }
                
                endRepeatAfterOccurrencesButton
                
                if recurrenceState.showEndRepeatAfterOccurrencesPicker {
                    endRepeatOccurrencesPicker
                }
            }
        }.navigationTitle("End repeat")
    }
    
    // MARK: - End Repeat Never Button
    var endRepeatNeverButton: some View {
        Button {
            withAnimation {
                recurrenceState.endRepeat = .never
            }
        } label: {
            HStack {
                Text("Repeat Forever")
                    .foregroundStyle(UIColor.label.toColor())
                Spacer()
                if recurrenceState.endRepeat == .never {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    // MARK: - End Repeat On Date Button
    var endRepeatOnDateButton: some View {
        Button {
            withAnimation {
                recurrenceState.endRepeat = .onDate
            }
        } label: {
            HStack {
                Text("End Repeat Date")
                    .foregroundStyle(UIColor.label.toColor())
                Spacer()
                if recurrenceState.endRepeat == .onDate {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    // MARK: - End Repeat Date Picker
    var endRepeatDatePicker: some View {
        DatePicker(selection: $recurrenceState.endRepeatDate, in: Date.now..., displayedComponents: .date) {
            Text("Select a date")
        }.datePickerStyle(.graphical)
    }
    
    // MARK: - End Repeat After Occurrences Button
    var endRepeatAfterOccurrencesButton: some View {
        Button {
            withAnimation {
                recurrenceState.endRepeat = .afterOccurrences
                
                if !recurrenceState.showEndRepeatAfterOccurrencesPicker {
                    recurrenceState.showEndRepeatAfterOccurrencesPicker = true
                }
            }
        } label: {
            HStack {
                Text("After")
                    .foregroundStyle(UIColor.label.toColor())
                Spacer()
                Text("\(recurrenceState.endRepeatAfterOccurrences) occurrence\(recurrenceState.endRepeatAfterOccurrences > 1 ? "s" : "")")
                    .foregroundStyle(recurrenceState.endRepeat == .afterOccurrences ? .accentColor : UIColor.label.toColor())
            }
        }
    }
    
    // MARK: - End Repeat Occurrences Picker
    var endRepeatOccurrencesPicker: some View {
        Picker("Count", selection: $recurrenceState.endRepeatAfterOccurrences) {
            ForEach(1...999, id: \.self) { occurrence in
                HStack {
                    Text("\(occurrence)")
                        .tag(occurrence)
                }
            }
        }.pickerStyle(.wheel)
    }
}
