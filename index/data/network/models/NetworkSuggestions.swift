//
//  NetworkSuggestions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

struct NetworkListTemplateSuggestion: Codable {
    let name: String
    let color: String
}

struct NetworkCategoryTemplateSuggestion: Codable {
    let name: String
    let color: String
}

struct NetworkItemTemplateSuggestion: Codable {
    let name: String
}

struct NetworkTaskTemplateSuggestion: Codable {
    let name: String
}

struct NetworkColorsSuggestion: Codable {
    let id: String
    let description: String
    let colors: [String]
}
