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
    let item_id: String?
    let subtasks: [NetworkSubTask]
    let due_date: Date?
    let rrule: String?
    let priority: Int?
    let reminders: [NetworkTaskReminder]
}
