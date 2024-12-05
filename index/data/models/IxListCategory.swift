//
//  IxListCategory.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/12/24.
//
import Foundation
import SwiftData

@Model
class IxListCategory {
    @Attribute(.unique) var id: String
    var user_id: String
    var list_id: String
    var name: String
    var color: String
    var created_at: Int64
    var edited_at: Int64?
    
    init(id: String, user_id: String, list_id: String, name: String, color: String, created_at: Int64, edited_at: Int64? = nil) {
        self.id = id
        self.user_id = user_id
        self.list_id = list_id
        self.name = name
        self.color = color
        self.created_at = created_at
        self.edited_at = edited_at
    }
    
    convenience init(networkListCategory: NetworkListCategory) {
        self.init(
            id: networkListCategory.id,
            user_id: networkListCategory.user_id,
            list_id: networkListCategory.list_id,
            name: networkListCategory.name,
            color: networkListCategory.color,
            created_at: networkListCategory.created_at,
            edited_at: networkListCategory.edited_at
        )
    }
}
