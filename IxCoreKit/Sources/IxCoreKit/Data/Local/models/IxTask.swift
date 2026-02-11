//
//  IxTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
public final class IxTask: Sanitizable, Validatable, EmptyInitializable {
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
        taskDescription = description
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
            userId: networkTask.userId,
            itemId: networkTask.itemId,
            name: networkTask.name,
            description: networkTask.description,
            subtasks: networkTask.subtasks.map { IxSubTask(name: $0.name, completed: $0.completed) },
            dueDate: networkTask.dueDate,
            rrule: networkTask.rrule,
            completed: networkTask.completed,
            priority: networkTask.priority,
            reminders: networkTask.reminders.map { IxTaskReminder(daysBefore: $0.daysBefore, timeOffset: $0.timeOffset) },
            createdAt: networkTask.createdAt,
            editedAt: networkTask.editedAt,
            completedAt: networkTask.completedAt
        )
    }

    /// Returns a 'COMPLETED {date}' string if the task is completed, just the date otherwise
    public var taskRowDate: String {
        if let completedAt = completedAt {
            let completionDate = Date(timeIntervalSince1970: Double(completedAt / 1000))
            return "COMPLETED \(DateHelper.Formatters.taskRowDate.string(from: completionDate))"
        } else {
            guard let dueDate = dueDate else { return "" }
            return DateHelper.Formatters.taskRowDate.string(from: dueDate)
        }
    }

    public static func priorityColor(_ priority: Int) -> Color {
        return switch priority {
        case 0: .gray
        case 1: .green
        case 2: .orange
        case 3: .red
        default: .gray
        }
    }

    public static func empty() -> IxTask {
        return IxTask(
            id: "",
            userId: "",
            itemId: nil,
            name: "",
            description: nil,
            subtasks: [],
            dueDate: nil,
            rrule: nil,
            completed: false,
            priority: nil,
            reminders: [],
            createdAt: Date().timeMillis(),
            editedAt: nil,
            completedAt: nil
        )
    }

    public static func empty(
        dueDate: Date? = nil
    ) -> IxTask {
        return IxTask(
            id: "",
            userId: "",
            itemId: nil,
            name: "",
            description: nil,
            subtasks: [],
            dueDate: dueDate,
            rrule: nil,
            completed: false,
            priority: nil,
            reminders: [],
            createdAt: Date().timeMillis(),
            editedAt: nil,
            completedAt: nil
        )
    }

    public var validationRes: Result<Void, ValidationError> {
        if name.isEmpty {
            return .failure(.init("Task name cannot be empty"))
        }

        if name.count > IxValidations.Task.maxNameLength {
            return .failure(.init("Task name can be \(IxValidations.Task.maxNameLength) characters maximum"))
        }

        if taskDescription?.count ?? 0 > IxValidations.Task.maxDescriptionLength {
            return .failure(.init("Task description can be \(IxValidations.Task.maxDescriptionLength) characters maximum"))
        }

        if subtasks.count > IxValidations.Task.maxSubtaskCount {
            return .failure(.init("Task can have maximum \(IxValidations.Task.maxSubtaskCount) subtasks"))
        }

        if reminders.count > IxValidations.Task.maxRemindersCount {
            return .failure(.init("Task can have maximum \(IxValidations.Task.maxRemindersCount) reminders"))
        }

        return .success(())
    }

    public var sanitized: IxTask {
        let copy = self

        copy.name = name.sanitized
        copy.taskDescription = taskDescription?.sanitized

        return copy
    }

    public static func mock(
        name: String,
        description: String? = nil,
        completed: Bool = false,
        dueDate: Date? = nil,
        priority: Int? = nil,
        id: String = UUID().uuidString,
        userId: String = UUID().uuidString
    ) -> IxTask {
        return IxTask(
            id: id,
            userId: userId,
            itemId: nil,
            name: name,
            description: description,
            subtasks: [],
            dueDate: dueDate,
            rrule: nil,
            completed: completed,
            priority: priority,
            reminders: [],
            createdAt: Date.now.timeMillis(),
            editedAt: nil,
            completedAt: nil
        )
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
    /// The number of days before the due date when the reminder should trigger.
    public var daysBefore: Int64

    /// The time offset in milliseconds from the start of the day (00:00) at which the reminder should trigger.
    public var timeOffset: Int64

    public init(daysBefore: Int64, timeOffset: Int64) {
        self.daysBefore = daysBefore
        self.timeOffset = timeOffset
    }
    
    public func asDate(taskDueDate: Date) -> Date {
        let calendar = DateHelper.calendar()
        let reminderDate = calendar.date(byAdding: .day, value: Int(daysBefore), to: taskDueDate) ?? Date.now
        return calendar.startOfDay(for: reminderDate).addingTimeInterval(Double(timeOffset) / 1000)
    }

    /// Returns a formatted string representing the reminder time (e.g., "8:00 AM") in the user's locale.
    /// - Returns: A short time string based on the local time of the reminder.
    public func hourAndMinuteString() -> String {
        // Convert milliseconds to seconds and add to start of the day
        let targetDate = asDate(taskDueDate: .now)

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        formatter.timeZone = .current

        return formatter.string(from: targetDate)
    }
}
