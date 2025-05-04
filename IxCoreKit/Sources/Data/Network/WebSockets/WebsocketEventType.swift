//
//  Untitled.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

enum WebsocketEventType: String, Codable {
    /// All user auth sessions should be closed
    case userAuthSessionsInvalidated = "USER_AUTH_SESSIONS_INVALIDATED"
    case userUpdated = "USER_UPDATED"
    
    case listCreated = "LIST_CREATED"
    case listUpdated = "LIST_UPDATED"
    case listDeleted = "LIST_DELETED"
    
    case categoryCreated = "CATEGORY_CREATED"
    case categoryUpdated = "CATEGORY_UPDATED"
    case categoryDeleted = "CATEGORY_DELETED"
    
    case itemCreated = "ITEM_CREATED"
    case itemUpdated = "ITEM_UPDATED"
    case itemDeleted = "ITEM_DELETED"
    
    case taskCreated = "TASK_CREATED"
    case taskUpdated = "TASK_UPDATED"
    case taskDeleted = "TASK_DELETED"
}
