//
//  ItemFilter.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/12/24.
//

enum ItemsFilter: String, CaseIterable, Identifiable {
    case all = "All";
    case uncompleted = "Uncompleted";
    case completed = "Completed";
    
    var id: Self { self }
}
