//
//  IxDateUtils.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/03/25.
//

import Foundation

struct IxDateUtils {
    static let oneDayMillis: Double = 60 * 60 * 24
    static let twoDayMillis = oneDayMillis * 2
    static let threeDayMillis = oneDayMillis * 3
    static let fourDayMillis = oneDayMillis * 4
    static let fiveDayMillis = oneDayMillis * 5
    static let sixDayMillis = oneDayMillis * 6
    static let sevenDayMillis = oneDayMillis * 7
    static let eightDayMillis = oneDayMillis * 8
    
    struct Formatters {
        static let shared = Formatters()
        
        let taskDueDate: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE d MMM"
            formatter.timeZone = TimeZone.gmt
            
            return formatter
        }()
        
        let taskDueDatePicker: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMMM YYYY"
            formatter.timeZone = TimeZone.gmt
            
            return formatter
        }()
        
        let taskSectionHeading: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.timeZone = TimeZone.gmt
            
            return formatter
        }()
        
        let taskSectionSubheading: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM"
            formatter.timeZone = TimeZone.gmt
            
            return formatter
        }()
    }
    
    static func reminderOffsetToUtc(_ offset: Int64) -> Int64 {
        return offset - Int64(TimeZone.current.secondsFromGMT() * 1000)
    }
    
    static func reminderOffsetFromUtc(_ offset: Int64) -> Int64 {
        return offset + Int64(TimeZone.current.secondsFromGMT() * 1000)
    }
}
