//
//  ListItemsMoveReqBody.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

struct ListItemsMoveReqBody: Codable {
    let ids: [String]
    let listId: String?
    let categoryId: String?
}
