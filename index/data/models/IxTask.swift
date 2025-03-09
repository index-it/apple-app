//
//  IxTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import Foundation
import SwiftData

@Model
class IxTask {
    @Attribute(.unique) var id: String
    var user_id: String
    var item_id: String?
    var name: String
    var task_description: String?
    var subtasks: [IxSubTask]
    var due_date: Date?
    var rrule: String?
    var completed: Bool
    var priority: Int?
    var reminders: [IxTaskReminder]
    var created_at: Int64
    var edited_at: Int64?
    var completed_at: Int64?
    
    init(id: String, userId: String, itemId: String?, name: String, description: String?, subtasks: [IxSubTask], dueDate: Date?, rrule: String?, completed: Bool, priority: Int?, reminders: [IxTaskReminder], createdAt: Int64, editedAt: Int64? = nil, completedAt: Int64?) {
        self.id = id
        self.user_id = userId
        self.item_id = itemId
        self.name = name
        self.task_description = description
        self.subtasks = subtasks
        self.due_date = dueDate
        self.rrule = rrule
        self.completed = completed
        self.priority = priority
        self.reminders = reminders
        self.created_at = createdAt
        self.edited_at = editedAt
        self.completed_at = completedAt
    }
    
    convenience init(networkTask: NetworkTask) {
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
    
    func dueDateString() -> String {
        if let completed_at = completed_at {
            let completionDate = Date(timeIntervalSince1970: Double(completed_at / 1000))
            return "COMPLETED \(IxDateUtils.Formatters.shared.taskDueDate.string(from: completionDate.toLocalDate()))"
        } else {
            guard let dueDate = due_date else { return "" }
            return IxDateUtils.Formatters.shared.taskDueDate.string(from: dueDate.toLocalDate())
        }
    }
}

struct IxSubTask: Codable, Hashable {
    var name: String
    var completed: Bool
    
    init(name: String, completed: Bool) {
        self.name = name
        self.completed = completed
    }
}

struct IxTaskReminder: Codable, Hashable {
    var days_before: Int64
    var time_offset: Int64
    
    init(daysBefore: Int64, timeOffset: Int64) {
        self.days_before = daysBefore
        self.time_offset = timeOffset
    }
    
    func hourAndMinuteString() -> String {
        let startOfDay = Calendar.current.startOfDay(for: Date.now)
        // Convert milliseconds to seconds and add to start of the day
        let targetDate = startOfDay.addingTimeInterval(Double(time_offset) / 1000)

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current

        return formatter.string(from: targetDate)
    }
}
