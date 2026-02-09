//
//  RecurrenceState.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//

//
//  RecurrenceState.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/25.
//

import EventKit
import SwiftUI

// MARK: Models

enum RecurrenceFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: Self { self }
}

enum WeeklyFrequency: String, CaseIterable, Identifiable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"

    var id: Self { self }
}

enum MonthlyWeekdayFrequency: String, CaseIterable, Identifiable {
    case first
    case second
    case third
    case fourth
    case fifth
    case last

    var id: Self { self }
}

enum MonthlyWeekdayFrequencyTarget: String, CaseIterable, Identifiable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    // following are not supported in EventKit?
    //    case day = "day";
    //    case weekday = "weekday";
    //    case weekendDay = "weekend day";

    var id: Self { self }
}

enum EndRepeat {
    case never
    case onDate
    case afterOccurrences
}

// MARK: State class

@Observable
class RecurrenceState {
    var recurrenceEnabled = false
    var showRecurrenceFrequencyPicker = false
    var recurrenceFrequency: RecurrenceFrequency = .daily
    var showRecurrenceCountPicker = false
    var recurrenceCount = 1
    var weeklyFrequencies: Set<WeeklyFrequency> = Set()
    var monthEachSelected = true
    var monthFrequencies: Set<Int> = [1]
    var monthlyWeekdayFrequency = MonthlyWeekdayFrequency.first
    var monthlyWeekdayFrequencyTarget = MonthlyWeekdayFrequencyTarget.sunday
    var yearFrequencies: Set<Int> = [1]
    var yearDaysOfWeekSelected = false
    var yearlyWeekdayFrequency = MonthlyWeekdayFrequency.first
    var yearlyWeekdayFrequencyTarget = MonthlyWeekdayFrequencyTarget.sunday
    var endRepeat = EndRepeat.never
    var endRepeatDate = Date.now
    var endRepeatAfterOccurrences = 30
    var showEndRepeatAfterOccurrencesPicker = false

    var everyButtonValue: String {
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

    func parseRRule(_ rrule: String?) {
        if let rrule = rrule {
            let rule = EKRecurrenceRule.recurrenceRuleFromString(rrule)
            if let rule = rule {
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
                            self.weeklyFrequencies.insert(.sunday)
                        case .monday:
                            self.weeklyFrequencies.insert(.monday)
                        case .tuesday:
                            self.weeklyFrequencies.insert(.tuesday)
                        case .wednesday:
                            self.weeklyFrequencies.insert(.wednesday)
                        case .thursday:
                            self.weeklyFrequencies.insert(.thursday)
                        case .friday:
                            self.weeklyFrequencies.insert(.friday)
                        case .saturday:
                            self.weeklyFrequencies.insert(.saturday)
                        }
                    }
                case .monthly:
                    recurrenceFrequency = .monthly

                    if rule.daysOfTheMonth != nil, !rule.daysOfTheMonth!.isEmpty {
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

                    if rule.monthsOfTheYear != nil, !rule.monthsOfTheYear!.isEmpty {
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
                @unknown default:
                    fatalError("EKRecurrenceRule frequency is of an unknown type")
                }
            }
        }
    }

    func generateRRule() -> String? {
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

                for day in weeklyFrequencies {
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

            if recurrenceWith == .monthly, !monthEachSelected {
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

            if recurrenceWith == .yearly, yearDaysOfWeekSelected {
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
            if recurrenceWith == .monthly, monthEachSelected {
                daysOfTheMonth = Array(monthFrequencies.map { number in
                    NSNumber(value: number)
                })
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

            return eKRecurrenceRule.lastRRuleString()
        } else {
            return nil
        }
    }
}
