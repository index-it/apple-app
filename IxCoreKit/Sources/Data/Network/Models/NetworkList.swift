//
//  NetworkList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation

public struct NetworkList: Codable, Sendable {
    public let id: String
    public let user_id: String
    public let name: String
    public let icon: String
    public let color: String
    public let archived: Bool
    public let is_public: Bool
    public let viewers: [String]
    public let editors: [String]
    public let created_at: Int64
    public let edited_at: Int64?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case name
        case icon
        case color
        case archived
        case is_public = "public"
        case viewers
        case editors
        case created_at
        case edited_at
    }
}
