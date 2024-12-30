//
//  ItemFilter.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/12/24.
//

enum CategorySorting: String, CaseIterable, Identifiable {
    case name = "Name";
    case creation = "Creation date";
    case edit = "Last edit";
    
    var id: Self { self }
}
