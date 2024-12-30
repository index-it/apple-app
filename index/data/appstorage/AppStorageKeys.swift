//
//  AppStorageKeys.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import SwiftUI

struct AppStorageKeys {
    // MARK: user & templates
    static let logged_in_user = "logged_in_user"
    static let colors_suggestions = "colors_suggestions"
    
    // MARK: list
    static let list_filter = "list_filter"
    static let list_sorting = "list_sorting"
    static let list_reverse_sorting = "list_reverse_sorting"
    
    // MARK: item
    static let item_filter = "item_filter"
    static let item_sorting = "item_sorting"
    static let item_reverse_sorting = "item_reverse_sorting"
    
    // MARK: category
    static func show_uncategorized_items(_ listId: String) -> String {
        return "show_uncategorized_items/\(listId)"
    }
    static let category_sorting = "category_sorting"
    static let category_reverse_sorting = "category_reverse_sorting"
    
    struct Defaults {
        static let colors = [Color.green, Color.purple, Color.yellow, Color.orange, Color.cyan, Color.pink, Color.indigo]
        
        // MARK: list defaults
        static let list_filter = ListFilter.all
        static let list_sorting = ListSorting.creation
        static let list_reverse_sorting = false
        
        // MARK: item defaults
        static let item_filter = ItemFilter.uncompleted
        static let item_sorting = ItemSorting.creation
        static let item_reverse_sorting = false
        
        // MARK: category defaults
        static let show_uncategorized_items = true
        static let category_sorting = CategorySorting.creation
        static let category_reverse_sorting = false
    }
}
