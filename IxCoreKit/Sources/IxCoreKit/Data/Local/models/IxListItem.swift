//
//  IxListItem.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import Foundation
import SwiftData

@Model
public class IxListItem {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var listId: String
    public var categoryId: String?
    public var name: String
    public var completed: Bool
    public var link: String?
    public var note: String?
    public var createdAt: Int64
    public var editedAt: Int64?
    public var completedAt: Int64?
    
    public init(id: String, user_id: String, list_id: String, category_id: String?, name: String, completed: Bool, link: String?, note: String?, created_at: Int64, edited_at: Int64?, completed_at: Int64?) {
        self.id = id
        self.userId = user_id
        self.listId = list_id
        self.categoryId = category_id
        self.name = name
        self.completed = completed
        self.link = link
        self.note = note
        self.createdAt = created_at
        self.editedAt = edited_at
        self.completedAt = completed_at
    }
    
    public convenience init(networkListItem: NetworkListItem) {
        self.init(
            id: networkListItem.id,
            user_id: networkListItem.userId,
            list_id: networkListItem.listId,
            category_id: networkListItem.categoryId,
            name: networkListItem.name,
            completed: networkListItem.completed,
            link: networkListItem.link,
            note: networkListItem.note,
            created_at: networkListItem.createdAt,
            edited_at: networkListItem.editedAt,
            completed_at: networkListItem.completedAt
        )
    }
}
