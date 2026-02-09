//
//  IxUniversalLinks.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

public enum IxUniversalLinks {
    public static let host = "web.index-it.app"

    public enum Sections {
        public static let lists = "lists"
        public static let callback = "callback"
        public static let categories = "categories"
        public static let items = "items"

        public static let tasks = "tasks"
        public static let settings = "settings"

        public static let quickAdd = "quick-add"
    }

    public enum QuickAddEntity: String {
        case task
        case item
    }

    public static var lists: String {
        "https://\(host)/\(Sections.lists)"
    }

    public static func list(_ listId: String) -> String {
        "https://\(host)/\(Sections.lists)/\(listId)"
    }
    
    public static func listInvite(_ token: String) -> String {
        "https://\(host)/\(Sections.callback)/lists/accept-invite?token=\(token)"
    }

    public static func categories(listId: String) -> String {
        "https://\(host)/\(Sections.lists)/\(listId)/categories"
    }

    public static func category(listId: String, _ categoryId: String) -> String {
        "https://\(host)/\(Sections.lists)/\(listId)?categoryId=\(categoryId)"
    }

    public static func item(listId: String, _ itemId: String) -> String {
        "https://\(host)/\(Sections.lists)/\(listId)?itemId=\(itemId)"
    }

    public static var tasks: String {
        "https://\(host)/\(Sections.tasks)"
    }

    public static func tasks(_ taskId: String) -> String {
        "https://\(host)/\(Sections.tasks)/\(taskId)"
    }

    public static var settings: String {
        "https://\(host)/\(Sections.settings)"
    }

    public static func quickAdd(_ entity: QuickAddEntity) -> String {
        "https://\(host)/\(Sections.quickAdd)/\(entity.rawValue)"
    }
}
