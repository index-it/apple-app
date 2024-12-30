//
//  ListsFilter.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

enum ListFilter: String, CaseIterable, Identifiable {
    case all = "All";
    case owner = "Owner";
    case shared = "Shared with me";
    
    var id: Self { self }
}
