//
//  NetworkList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation

struct NetworkList: Codable {
    let id: String
    let user_id: String
    let name: String
    let icon: String
    let color: String
    let is_public: Bool
    let viewers: [String]
    let editors: [String]
    let created_at: Int64
    let edited_at: Int64?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case name
        case icon
        case color
        case is_public = "public"
        case viewers
        case editors
        case created_at
        case edited_at
    }
    
    
}
