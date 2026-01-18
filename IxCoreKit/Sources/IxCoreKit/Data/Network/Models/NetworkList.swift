//
//  NetworkList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation

public struct NetworkList: Codable, Sendable {
    public let id: String
    public let userId: String
    public let name: String
    public let icon: String
    public let color: String
    public let archived: Bool
    public let isPublic: Bool
    public let viewers: [String]
    public let editors: [String]
    public let createdAt: Int64
    public let editedAt: Int64?

    public enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case icon
        case color
        case archived
        case isPublic = "public"
        case viewers
        case editors
        case createdAt
        case editedAt
    }
}
