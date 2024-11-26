//
//  NetworkListCategory.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

struct NetworkListCategory: Codable {
    let id: String
    let user_id: String
    let list_id: String
    let name: String
    let color: String
    let created_at: Int64
    let edited_at: Int64?
}
