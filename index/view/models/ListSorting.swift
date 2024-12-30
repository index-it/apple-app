//
//  ListsSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

enum ListSorting: String, CaseIterable, Identifiable {
    case name = "Name";
    case creation = "Creation date";
    
    var id: Self { self }
}
