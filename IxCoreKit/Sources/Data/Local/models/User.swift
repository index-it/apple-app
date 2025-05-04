//
//  NetworkUser.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

public struct User: Encodable, Decodable, Equatable, Sendable {
    public var id: String
    public var email: String
    public var has_pro: Bool
    public var creation_timestamp: Date
    public var creation_source: UserCreationSource
    
    public enum CodingKeys: String, CodingKey {
        case id
        case email
        case has_pro
        case creation_timestamp
        case creation_source
    }
    
    public init(from networkUser: NetworkUser) {
        self.id = networkUser.id
        self.email = networkUser.email
        self.has_pro = networkUser.has_pro
        self.creation_timestamp = networkUser.creation_timestamp
        self.creation_source = networkUser.creation_source
    }
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        email = try values.decode(String.self, forKey: .email)
        has_pro = try values.decode(Bool.self, forKey: .has_pro)
        creation_timestamp = try values.decode(Date.self, forKey: .creation_timestamp)
        creation_source = try values.decode(UserCreationSource.self, forKey: .creation_source)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(has_pro, forKey: .has_pro)
        try container.encode(creation_timestamp, forKey: .creation_timestamp)
        try container.encode(creation_source, forKey: .creation_source)
    }
}
