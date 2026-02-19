//
//  TaskPriority.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 06/02/26.
//

 import AppIntents


enum TaskPriorityEnum: Int, AppEnum, CaseIterable {
    case none = 0
    case veryLow = 1
    case low = 2
    case medium = 3
    case high = 4

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Task priority"

    static let caseDisplayRepresentations: [TaskPriorityEnum: DisplayRepresentation] = [
        .none: "None",
        .veryLow: "Very low",
        .low: "Low",
        .medium: "Medium",
        .high: "High",
    ]
 }
