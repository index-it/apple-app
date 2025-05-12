//
//  TaskCreateOrEditReqBody.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

import Foundation

struct TaskCreateOrEditReqBody: Codable {
    let name: String
    let description: String?
    let itemId: String?
    let subtasks: [NetworkSubTask]
    let dueDate: Date?
    let rrule: String?
    let priority: Int?
    let reminders: [NetworkTaskReminder]
}
