//
//  NetworkUser.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

struct NetworkUser: Codable, Equatable {
    var id: String
    var email: String
    var has_pro: Bool
    var creation_timestamp: Date
    var creation_source: UserCreationSource
}
