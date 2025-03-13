//
//  WebsocketEventData.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

/// Represents a websocket event that should be sent to a user
struct WebsocketEventData: Decodable {
    let fromSessionId: String?
    let fromUserId: String?
    let type: WebsocketEventType
    let inclusive: Bool
    let content: WebsocketEventContent
}
