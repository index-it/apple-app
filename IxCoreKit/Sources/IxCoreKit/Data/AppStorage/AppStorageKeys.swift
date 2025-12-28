//
//  AppStorageKeys.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import SwiftUI

/// Constants for AppStorage keys used throughout the app
public enum AppStorageKeys {
    public static let onboardingShowed = "onboarding_showed"
    
    public static let loggedInUser = "logged_in_user"
    
    public enum Lists {
        public static let filter = "lists_filter"
        public static let sorting = "lists_sorting"
        public static let sortOrder = "lists_sorting_order"
    }
    
    public enum Items {
        public static func sorting(_ listId: String) -> String {
            return "items_sorting/\(listId)"
        }
        public static func sortOrder(_ listId: String) -> String {
            return "items_sorting_order/\(listId)"
        }
        public static func show_completed(_ listId: String) -> String {
            return "items_show_completed/\(listId)"
        }
    }
    
    public enum Categories {
        public static func hideUncategorized(_ listId: String) -> String {
            return "hide_uncategorized/\(listId)"
        }
        public static func filter(_ listId: String) -> String {
            return "categories_filter/\(listId)"
        }
        public static func sorting(_ listId: String) -> String {
            return "categories_sorting/\(listId)"
        }
        public static func sortOrder(_ listId: String) -> String {
            return "categories_sorting_order/\(listId)"
        }
    }
    
    public enum Tasks {
        public static let sorting = "tasks_sorting"
        public static let sortOrder = "tasks_sorting_order"
        public static let unplannedTasksSectionEspanded = "unplanned_tasks_section_expanded"
    }
    
    /// Default values for AppStorage keys
    public enum Defaults {
        public static let listsFilter = ListsFilter.all
        public static let listsSorting = ListsSorting.creationDate
        public static let listsSortOrder = SortOrder.reverse
        
        public static let itemsSorting = ItemsSorting.creationDate
        public static let itemsSortOrder = SortOrder.reverse
        public static let itemsShowCompleted = false
        
        public static let hideUncategorized = false
        public static let categoriesSorting = CategoriesSorting.creationDate
        public static let categoriesSortOrder = SortOrder.reverse
        
        public static let tasksSorting = TasksSorting.priority
        public static let tasksSortOrder = SortOrder.reverse
        public static let unplannedTasksSectionEspanded = true
    }
}
