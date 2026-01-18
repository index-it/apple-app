//
//  SyncResource.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 02/05/25.
//

public enum SyncResource {
    public static let lists = "lists"
    public static let tasks = "tasks"
    public static let completedTasks = "completed-tasks"

    public static func list(_ listId: String) -> String {
        return "\(lists)/\(listId)"
    }

    public static func listCategories(_ listId: String) -> String {
        return "\(lists)/\(listId)/categories"
    }

    public static func listItems(_ listId: String) -> String {
        return "\(lists)/\(listId)/items"
    }

    public static func listItem(_ listId: String, _ itemId: String) -> String {
        return "\(lists)/\(listId)/\(itemId)"
    }

    public static func task(_ taskId: String) -> String {
        return "\(tasks)/\(taskId)"
    }
}
