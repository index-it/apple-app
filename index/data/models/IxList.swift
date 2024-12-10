//
//  List.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation
import SwiftData

@Model
class IxList {
    @Attribute(.unique) var id: String
    var user_id: String
    var name: String
    var icon: String
    var color: String
    var is_public: Bool
    var viewers: [String]
    var editors: [String]
    var created_at: Int64
    var edited_at: Int64?
    
    init(id: String, userId: String, name: String, emoji: String, color: String, isPublic: Bool, viewers: [String], editors: [String], createdAt: Int64, editedAt: Int64? = nil) {
        self.id = id
        self.user_id = userId
        self.name = name
        self.icon = emoji
        self.color = color
        self.is_public = isPublic
        self.viewers = viewers
        self.editors = editors
        self.created_at = createdAt
        self.edited_at = editedAt
    }
    
    convenience init(networkList: NetworkList) {
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
    
    func isShared() -> Bool {
        return self.is_public || !self.viewers.isEmpty || !self.editors.isEmpty
    }
    
    static func loading(
        name: String? = nil,
        emoji: String? = nil,
        color: String? = nil
    ) -> IxList {
        return IxList(
            id: UUID().uuidString,
            userId: "loading",
            name: name ?? "",
            emoji: emoji ?? "🏝️",
            color: color ?? "#000000",
            isPublic: false,
            viewers: [],
            editors: [],
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            editedAt: nil
        )
    }
}
