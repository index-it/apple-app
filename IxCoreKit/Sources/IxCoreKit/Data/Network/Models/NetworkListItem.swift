//
//  NetworkListItem.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkListItem: Codable, Sendable {
    public let id: String
    public let userId: String
    public let listId: String
    public let categoryId: String?
    public let name: String
    public let completed: Bool
    public let link: String?
    public let note: String?
    public let createdAt: Int64
    public let editedAt: Int64?
    public let completedAt: Int64?
}
