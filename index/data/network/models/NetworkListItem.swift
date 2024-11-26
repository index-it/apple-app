//
//  NetworkListItem.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

struct NetworkListItem: Codable {
    let id: String
    let user_id: String
    let list_id: String
    let category_id: String?
    let name: String
    let completed: Bool
    let link: String?
    let created_at: Int64
    let edited_at: Int64?
    let completed_at: Int64?
}
