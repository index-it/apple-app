//
//  TaskSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 01/03/25.
//

enum TaskSorting: String, CaseIterable, Identifiable {
    case name = "Name";
    case priority = "Priority";
    case creation = "Creation date";
    
    var id: Self { self }
}
