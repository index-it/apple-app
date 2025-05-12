//
//  ListItemCreateOrEditReqBody.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/11/24.
//

struct ListItemCreateOrEditReqBody: Codable {
    let name: String
    let categoryId: String?
    let link: String?
    let note: String?
}
