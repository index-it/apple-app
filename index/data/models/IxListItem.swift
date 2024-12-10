//
//  IxListItem.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import Foundation
import SwiftData

@Model
class IxListItem {
    @Attribute(.unique) var id: String
    var user_id: String
    var list_id: String
    var category_id: String?
    var name: String
    var completed: Bool
    var link: String?
    var created_at: Int64
    var edited_at: Int64?
    var completed_at: Int64?
    
    init(id: String, user_id: String, list_id: String, category_id: String?, name: String, completed: Bool, link: String?, created_at: Int64, edited_at: Int64?, completed_at: Int64?) {
        self.id = id
        self.user_id = user_id
        self.list_id = list_id
        self.category_id = category_id
        self.name = name
        self.completed = completed
        self.link = link
        self.created_at = created_at
        self.edited_at = edited_at
        self.completed_at = completed_at
    }
    
    convenience init(networkListItem: NetworkListItem) {
        self.init(
            id: networkListItem.id,
            user_id: networkListItem.user_id,
            list_id: networkListItem.list_id,
            category_id: networkListItem.category_id,
            name: networkListItem.name,
            completed: networkListItem.completed,
            link: networkListItem.link,
            created_at: networkListItem.created_at,
            edited_at: networkListItem.edited_at,
            completed_at: networkListItem.completed_at
        )
    }
    
    static func loading() -> IxListItem {
        IxListItem(id: UUID().uuidString, user_id: "", list_id: "", category_id: nil, name: "Loading...", completed: false, link: nil, created_at: 0, edited_at: 0, completed_at: 0)
    }
}
