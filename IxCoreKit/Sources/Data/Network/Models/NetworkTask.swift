//
//  NetworkTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkTask: Codable {
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

public struct NetworkSubTask: Codable {
    public let name: String
    public let completed: Bool
}

public struct NetworkTaskReminder: Codable {
    public let days_before: Int64
    public let time_offset: Int64
}
