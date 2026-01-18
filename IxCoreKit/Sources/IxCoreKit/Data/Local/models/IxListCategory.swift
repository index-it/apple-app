//
//  IxListCategory.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/12/24.
//
import Foundation
import SwiftData

@Model
public class IxListCategory {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var listId: String
    public var name: String
    public var color: String?
    public var createdAt: Int64
    public var editedAt: Int64?

    public init(id: String, user_id: String, list_id: String, name: String, color: String?, created_at: Int64, edited_at: Int64? = nil) {
        self.id = id
        userId = user_id
        listId = list_id
        self.name = name
        self.color = color
        createdAt = created_at
        editedAt = edited_at
    }

    public convenience init(networkListCategory: NetworkListCategory) {
        self.init(
            id: networkListCategory.id,
            user_id: networkListCategory.userId,
            list_id: networkListCategory.listId,
            name: networkListCategory.name,
            color: networkListCategory.color,
            created_at: networkListCategory.createdAt,
            edited_at: networkListCategory.editedAt
        )
    }

    public static func mock(
        name: String,
        color: String?,
        listId: String = UUID().uuidString,
        userId: String = UUID().uuidString
    ) -> IxListCategory {
        return IxListCategory(
            id: UUID().uuidString,
            user_id: userId,
            list_id: listId,
            name: name,
            color: color,
            created_at: Date.now.currentTimeMillis(),
            edited_at: nil
        )
    }
}
