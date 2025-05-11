//
//  NetworkUser.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

public struct NetworkUser: Codable, Equatable, Sendable {
    public var id: String
    public var email: String
    public var has_pro: Bool
    public var creation_timestamp: Date
    public var creation_source: UserCreationSource
}
