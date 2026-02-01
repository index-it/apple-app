//
//  NetworkTaskConnectedItems.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 01/02/26.
//

struct NetworkTaskConnectedItems: Codable, Sendable {
    public let items: [NetworkListItem]
    public let categories: [NetworkListCategory]
    public let lists: [NetworkList]
}
