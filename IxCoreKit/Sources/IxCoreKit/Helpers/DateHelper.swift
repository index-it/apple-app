//
//  DateHelper.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/03/25.
//

import Foundation

public enum DateHelper {
    public static let oneDaySeconds: Double = 60 * 60 * 24
    public static let twoDaySeconds = oneDaySeconds * 2
    public static let threeDaySeconds = oneDaySeconds * 3
    public static let fourDaySeconds = oneDaySeconds * 4
    public static let fiveDaySeconds = oneDaySeconds * 5
    public static let sixDaySeconds = oneDaySeconds * 6
    public static let sevenDaySeconds = oneDaySeconds * 7
    public static let eightDaySeconds = oneDaySeconds * 8

    public enum Formatters {
        private static func makeFormatter(format: String, timeZone: TimeZone = .current) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = timeZone
            return formatter
        }

        // TODO: Give proper name
        public static let taskRowDate = makeFormatter(format: "EEE d MMM")
        public static let taskDueDatePicker = makeFormatter(format: "EEEE, d MMMM YYYY")
        public static let taskSectionHeading = makeFormatter(format: "EEEE")
        public static let taskSectionSubheading = makeFormatter(format: "d MMMM")

        public static let dateTime = makeFormatter(format: "EEE d MMM at HH:mm")
    }

    /// Returns a calendar instance that uses the local timezone
    public static func localCalendar() -> Calendar {
        return Calendar.current
    }

    /// Returns a calendar instance that uses the UTC timezone
    public static func calendar() -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }
    
    public static func utcDate(from localDateComponents: DateComponents) -> Date? {
        return localCalendar().date(from: localDateComponents)
    }

    public static func startOfDay() -> Date {
        return calendar().startOfDay(for: Date.now)
    }
    
    public static func millisFromStartOfDay() -> Int64 {
        return Int64(Date.now.timeIntervalSince(startOfDay()) * 1000)
    }

    /// Returns the time offset adjusted to the local timezone in milliseconds from midnight.
    public static func startOfDayOffsetFromUtcToLocal(offset: Int64) -> Int64 {
        return offset + Int64(TimeZone.current.secondsFromGMT() * 1000)
    }

    /// Returns the time offset adjusted in UTC timezone in milliseconds from midnight.
    public static func startOfDayOffsetFromLocalToUtc(offset: Int64) -> Int64 {
        return offset - Int64(TimeZone.current.secondsFromGMT() * 1000)
    }
    
    public static func daysDifference(_ from: Date, _ to: Date) -> Int {
        return calendar().dateComponents([.day], from: from, to: to).day ?? 0
    }
    
    public static func getUtcReminderTimeOffset(_ date: Date) -> Int64 {
        let components = calendar().dateComponents([.hour, .minute], from: date)
        let hoursInMs = Int64((components.hour ?? 0) * 60 * 60 * 1000)
        let minutesInMs = Int64((components.minute ?? 0) * 60 * 1000)
        
        return hoursInMs + minutesInMs
    }
    
    public static func getUtcReminderTimeOffset(from localDateComponents: DateComponents) -> Int64? {
        guard let hours = localDateComponents.hour, let minutes = localDateComponents.minute else {
            return nil
        }
        
        guard let date = localCalendar().date(from: localDateComponents) else {
            return nil
        }
        return getUtcReminderTimeOffset(date)
    }
}
