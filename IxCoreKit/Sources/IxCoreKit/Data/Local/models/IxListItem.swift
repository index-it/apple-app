//
//  IxListItem.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/12/24.
//

import Foundation
import SwiftData

@Model
public final class IxListItem: Validatable, Sanitizable, EmptyInitializable {
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
        userId = user_id
        listId = list_id
        categoryId = category_id
        self.name = name
        self.completed = completed
        self.link = link
        self.note = note
        createdAt = created_at
        editedAt = edited_at
        completedAt = completed_at
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

    public static var empty: IxListItem {
        return IxListItem(
            id: UUID().uuidString,
            user_id: UUID().uuidString,
            list_id: UUID().uuidString,
            category_id: nil,
            name: "",
            completed: false,
            link: nil,
            note: nil,
            created_at: Date().currentTimeMillis(),
            edited_at: nil,
            completed_at: nil
        )
    }

    public var validationRes: Result<Void, ValidationError> {
        if name.count >= 100 {
            return .failure(.init("Item name can be 100 characters maximum"))
        }

        return .success(())
    }

    public var sanitized: IxListItem {
        var copy = self

        copy.name = name.sanitized
        copy.link = link?.sanitized
        copy.note = note?.sanitized

        return copy
    }
}
