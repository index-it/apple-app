//
//  IxDateUtils.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/03/25.
//

import Foundation

public struct DateHelper {
    public static let oneDaySeconds: Double = 60 * 60 * 24
    public static let twoDaySeconds = oneDaySeconds * 2
    public static let threeDaySeconds = oneDaySeconds * 3
    public static let fourDaySeconds = oneDaySeconds * 4
    public static let fiveDaySeconds = oneDaySeconds * 5
    public static let sixDaySeconds = oneDaySeconds * 6
    public static let sevenDaySeconds = oneDaySeconds * 7
    public static let eightDaySeconds = oneDaySeconds * 8
    
    public struct Formatters {
        private static func makeFormatter(format: String, timeZone: TimeZone = .gmt) -> DateFormatter {
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
    }
    
    public static func reminderOffsetToUtc(_ offset: Int64) -> Int64 {
        return offset - Int64(TimeZone.current.secondsFromGMT() * 1000)
    }
}
