//
//  NetworkListCategory.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct NetworkListCategory: Codable, Sendable {
    public let id: String
    public let userId: String
    public let listId: String
    public let name: String
    public let color: String?
    public let createdAt: Int64
    public let editedAt: Int64?
}
