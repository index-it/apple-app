//
//  NetworkListSingleUserAccessInfo.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/11/24.
//

import Foundation

public struct IxListSingleUserAccessInfo: Codable, Sendable {
    public let userId: String
    public let email: String
    public let editor: Bool
}
