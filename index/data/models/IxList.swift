//
//  List.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation

struct IxList: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let emoji: String
    let color: String
    let isPublic: Bool
    let viewers: [String]
    let editors: [String]
    let createdAt: Int64
    let editedAt: Int64?
}
