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
    public var hasPro: Bool
    public var creationTimestamp: Int64
    public var creationSource: UserCreationSource
}
