//
//  IxList.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftData
import SwiftUI

@Model
public class IxList {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var name: String
    public var icon: String
    public var color: String
    public var archived: Bool
    public var isPublic: Bool
    public var viewers: [String]
    public var editors: [String]
    public var createdAt: Int64
    public var editedAt: Int64?

    public init(id: String, userId: String, name: String, emoji: String, color: String, archived: Bool, isPublic: Bool, viewers: [String], editors: [String], createdAt: Int64, editedAt: Int64? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        icon = emoji
        self.color = color
        self.archived = archived
        self.isPublic = isPublic
        self.viewers = viewers
        self.editors = editors
        self.createdAt = createdAt
        self.editedAt = editedAt
    }

    public convenience init(networkList: NetworkList) {
        self.init(
            id: networkList.id,
            userId: networkList.userId,
            name: networkList.name,
            emoji: networkList.icon,
            color: networkList.color,
            archived: networkList.archived,
            isPublic: networkList.isPublic,
            viewers: networkList.viewers,
            editors: networkList.editors,
            createdAt: networkList.createdAt,
            editedAt: networkList.editedAt
        )
    }

    /// A Boolean value indicating whether the list is shared with others.
    ///
    /// A list is considered shared if:
    /// - It is marked as public (`isPublic` is `true`)
    /// - It has one or more viewers
    /// - It has one or more editors
    ///
    /// - Returns: `true` if the list is public or has any viewers or editors; otherwise, `false`.
    public var isShared: Bool {
        isPublic || !viewers.isEmpty || !editors.isEmpty
    }

    public func getPermissions(userId: String) -> IxListPermission? {
        if userId == userId {
            return .owner
        } else if editors.contains(userId) {
            return .editor
        } else if viewers.contains(userId) {
            return .viewer
        } else {
            return nil
        }
    }

    public static func mock(
        name: String,
        emoji: String,
        color: String,
        archived: Bool = false,
        isPublic: Bool = false,
        id: String = UUID().uuidString,
        userId: String = UUID().uuidString
    ) -> IxList {
        return IxList(
            id: id,
            userId: userId,
            name: name,
            emoji: emoji,
            color: color,
            archived: archived,
            isPublic: isPublic,
            viewers: [],
            editors: [],
            createdAt: Date.now.currentTimeMillis(),
            editedAt: nil
        )
    }

    public static func loading() -> IxList {
        return IxList(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            name: NSLocalizedString("Loading...", comment: "List name loading"),
            emoji: "🔄",
            color: Color.accentColor.hexString,
            archived: false,
            isPublic: false,
            viewers: [],
            editors: [],
            createdAt: Date.now.currentTimeMillis(),
            editedAt: nil
        )
    }
}
