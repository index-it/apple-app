//
//  IxUniversalLinks.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

public struct IxUniversalLinks {
    public static let host = "web.index-it.app"
    
    public struct Sections {
        public static let lists = "lists"
        public static let categories = "categories"
        public static let items = "items"
        
        public static let tasks = "tasks"
        public static let settings = "settings"
    }
    
    public static var lists: String {
        "\(host)/\(Sections.lists)"
    }
    
    public static func list(_ listId: String) -> String {
        "\(host)/\(Sections.lists)/\(listId)"
    }
    
    public static func categories(listId: String) -> String {
        "\(host)/\(Sections.lists)/\(listId)/categories"
    }
    
    public static func category(listId: String, _ categoryId: String) -> String {
        "\(host)/\(Sections.lists)/\(listId)/categories/\(categoryId)"
    }
    
    public static func item(listId: String, _ itemId: String) -> String {
        "\(host)/\(Sections.lists)/\(listId)/items/\(itemId)"
    }
    
    public static var tasks: String {
        "\(host)/\(Sections.tasks)"
    }
    
    public static func tasks(_ taskId: String) -> String {
        "\(host)/\(Sections.tasks)/\(taskId)"
    }
    
    public static var settings: String {
        "\(host)/\(Sections.settings)"
    }
}
