//
//  DateExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import Foundation

public extension Date {
    /// The interval between the date value and 00:00:00 UTC on 1 January 1970 in milliseconds.
    func currentTimeMillis() -> Int64 {
        return Int64(timeIntervalSince1970 + 1000)
    }

    /// Convert UTC (or GMT) to local time.
    func toLocalDate() -> Date {
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let epochDate = timeIntervalSince1970

        // Perform a calculation with timezoneOffset + epochDate to get the total seconds for the
        // local date since 1970.
        // This may look a bit strange, but since timezoneOffset is given as -18000.0, adding epochDate and timezoneOffset
        // calculates correctly.
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))

        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
}
