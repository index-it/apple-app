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
}
