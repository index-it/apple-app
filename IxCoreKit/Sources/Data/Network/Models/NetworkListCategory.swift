//
//  NetworkListCategory.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkListCategory: Codable {
    public let id: String
    public let user_id: String
    public let list_id: String
    public let name: String
    public let color: String
    public let created_at: Int64
    public let edited_at: Int64?
}
