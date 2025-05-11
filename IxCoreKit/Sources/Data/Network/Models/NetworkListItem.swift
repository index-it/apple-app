//
//  NetworkListItem.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkListItem: Codable, Sendable {
    public let id: String
    public let user_id: String
    public let list_id: String
    public let category_id: String?
    public let name: String
    public let completed: Bool
    public let link: String?
    public let note: String?
    public let created_at: Int64
    public let edited_at: Int64?
    public let completed_at: Int64?
}
