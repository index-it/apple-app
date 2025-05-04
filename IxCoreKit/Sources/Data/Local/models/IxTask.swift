//
//  IxTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import Foundation
import SwiftData

@Model
public class IxTask {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var itemId: String?
    public var name: String
    public var taskDescription: String?
    public var subtasks: [IxSubTask]
    public var dueDate: Date?
    public var rrule: String?
    public var completed: Bool
    public var priority: Int?
    public var reminders: [IxTaskReminder]
    public var createdAt: Int64
    public var editedAt: Int64?
    public var completedAt: Int64?
    
    public init(id: String, userId: String, itemId: String?, name: String, description: String?, subtasks: [IxSubTask], dueDate: Date?, rrule: String?, completed: Bool, priority: Int?, reminders: [IxTaskReminder], createdAt: Int64, editedAt: Int64? = nil, completedAt: Int64?) {
        self.id = id
        self.userId = userId
        self.itemId = itemId
        self.name = name
        self.taskDescription = description
        self.subtasks = subtasks
        self.dueDate = dueDate
        self.rrule = rrule
        self.completed = completed
        self.priority = priority
        self.reminders = reminders
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.completedAt = completedAt
    }
    
    public convenience init(networkTask: NetworkTask) {
        self.init(
            id: networkTask.id,
            userId: networkTask.user_id,
            itemId: networkTask.item_id,
            name: networkTask.name,
            description: networkTask.description,
            subtasks: networkTask.subtasks.map { IxSubTask(name: $0.name, completed: $0.completed) },
            dueDate: networkTask.due_date,
            rrule: networkTask.rrule,
            completed: networkTask.completed,
            priority: networkTask.priority,
            reminders: networkTask.reminders.map { IxTaskReminder(daysBefore: $0.days_before, timeOffset: $0.time_offset) },
            createdAt: networkTask.created_at,
            editedAt: networkTask.edited_at,
            completedAt: networkTask.completed_at
        )
    }
    
    /// Returns a 'COMPLETED {date}' string if the task is completed, just the date otherwise
    public var taskRowDate: String {
        if let completedAt = completedAt {
            let completionDate = Date(timeIntervalSince1970: Double(completedAt / 1000))
            return "COMPLETED \(DateHelper.Formatters.taskRowDate.string(from: completionDate.toLocalDate()))"
        } else {
            guard let dueDate = dueDate else { return "" }
            return DateHelper.Formatters.taskRowDate.string(from: dueDate.toLocalDate())
        }
    }
}

public struct IxSubTask: Codable, Hashable {
    public var name: String
    public var completed: Bool
    
    public init(name: String, completed: Bool) {
        self.name = name
        self.completed = completed
    }
}

public struct IxTaskReminder: Codable, Hashable {
    public var daysBefore: Int64
    public var timeOffset: Int64
    
    public init(daysBefore: Int64, timeOffset: Int64) {
        self.daysBefore = daysBefore
        self.timeOffset = timeOffset
    }
    
    public init(daysBefore: Int64, localTimezoneOffset: Int64) {
        self.daysBefore = daysBefore
        self.timeOffset = localTimezoneOffset - Int64(TimeZone.current.secondsFromGMT() * 1000)
    }
    
    public var localTimezoneOffset: Int64 {
        return timeOffset + Int64(TimeZone.current.secondsFromGMT() * 1000)
    }
    
    public func hourAndMinuteString() -> String {
        let startOfDay = Calendar.current.startOfDay(for: Date.now)
        // Convert milliseconds to seconds and add to start of the day
        let targetDate = startOfDay.addingTimeInterval(Double(localTimezoneOffset) / 1000)

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current

        return formatter.string(from: targetDate)
    }
}
