//
//  SyncResponse.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 18/02/26.
//

struct ListsSyncResponse: Decodable {
    let lists: [NetworkList]
    let categories: [NetworkListCategory]
    let items: [NetworkListItem]
}
