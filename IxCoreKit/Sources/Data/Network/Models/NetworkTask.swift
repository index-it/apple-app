//
//  NetworkTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkTask: Codable, Sendable {
    public let id: String
    public let user_id: String
    public let item_id: String?
    public let name: String
    public let description: String?
    public let subtasks: [NetworkSubTask]
    public let due_date: Date?
    public let rrule: String?
    public let completed: Bool
    public let priority: Int?
    public let reminders: [NetworkTaskReminder]
    public let created_at: Int64
    public let edited_at: Int64?
    public let completed_at: Int64?
}

public struct NetworkSubTask: Codable, Sendable {
    public let name: String
    public let completed: Bool
}

public struct NetworkTaskReminder: Codable, Sendable {
    public let days_before: Int64
    public let time_offset: Int64
}
