//
//  NetworkTaskConnectedItems.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 01/02/26.
//

struct NetworkTaskConnectedItems: Codable, Sendable {
    let items: [NetworkListItem]
    let categories: [NetworkListCategory]
    let lists: [NetworkList]
}
