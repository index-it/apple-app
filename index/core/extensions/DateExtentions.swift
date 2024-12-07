//
//  DateExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import Foundation

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 + 1000)
    }
}
