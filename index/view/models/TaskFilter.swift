//
//  TaskFilter.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

enum TaskFilter: String, CaseIterable, Identifiable {
    case completed = "All";
    case uncompleted = "Owner";
    
    var id: Self { self }
}
