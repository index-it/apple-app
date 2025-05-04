//
//  List.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation
import SwiftData

@Model
public class IxList {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var name: String
    public var icon: String
    public var color: String
    public var isPublic: Bool
    public var viewers: [String]
    public var editors: [String]
    public var createdAt: Int64
    public var editedAt: Int64?
    
    public init(id: String, userId: String, name: String, emoji: String, color: String, isPublic: Bool, viewers: [String], editors: [String], createdAt: Int64, editedAt: Int64? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.icon = emoji
        self.color = color
        self.isPublic = isPublic
        self.viewers = viewers
        self.editors = editors
        self.createdAt = createdAt
        self.editedAt = editedAt
    }
    
    public convenience init(networkList: NetworkList) {
        self.init(
            id: networkList.id,
            userId: networkList.user_id,
            name: networkList.name,
            emoji: networkList.icon,
            color: networkList.color,
            isPublic: networkList.is_public,
            viewers: networkList.viewers,
            editors: networkList.editors,
            createdAt: networkList.created_at,
            editedAt: networkList.edited_at
        )
    }
    
    public var isShared: Bool {
        self.isPublic || !self.viewers.isEmpty || !self.editors.isEmpty
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
}
