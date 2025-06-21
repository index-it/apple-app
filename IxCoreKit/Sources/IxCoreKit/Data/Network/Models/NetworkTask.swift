//
//  NetworkTask.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkTask: Codable, Sendable {
    public let id: String
    public let userId: String
    public let itemId: String?
    public let name: String
    public let description: String?
    public let subtasks: [NetworkSubTask]
    public let dueDate: Date?
    public let rrule: String?
    public let completed: Bool
    public let priority: Int?
    public let reminders: [NetworkTaskReminder]
    public let createdAt: Int64
    public let editedAt: Int64?
    public let completedAt: Int64?
}

public struct NetworkSubTask: Codable, Sendable {
    public let name: String
    public let completed: Bool
}

public struct NetworkTaskReminder: Codable, Sendable {
    public let daysBefore: Int64
    public let timeOffset: Int64
}
