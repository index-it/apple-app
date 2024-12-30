//
//  ItemsSorting.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 30/12/24.
//

enum ItemSorting: String, CaseIterable, Identifiable {
    case name = "Name";
    case creation = "Creation date";
    case edit = "Last edit";
    
    var id: Self { self }
}
