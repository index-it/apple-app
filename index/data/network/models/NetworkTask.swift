//
//  NetworkTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

struct NetworkTask: Codable {
    let id: String
    let user_id: String
    let item_id: String?
    let name: String
    let description: String?
    let subtasks: [NetworkSubTask]
    let due_date: Date?
    let rrule: String?
    let completed: Bool
    let priority: Int?
    let reminders: [NetworkTaskReminder]
    let created_at: Int64
    let edited_at: Int64?
    let completed_at: Int64?
}

struct NetworkSubTask: Codable {
    let name: String
    let completed: Bool
}

struct NetworkTaskReminder: Codable {
    let days_before: Int64
    let time_offset: Int64
}
