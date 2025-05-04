//
//  NetworkListSingleUserAccessInfo.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

// TODO: Change all network structs from snake_case to camelCase
public struct IxListSingleUserAccessInfo: Codable {
    public let user_id: String
    public let email: String
    public let editor: Bool
}
