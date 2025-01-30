//
//  ListItemCreateOrEditReqBody.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/11/24.
//

struct ListItemCreateOrEditReqBody: Codable {
    let name: String
    let category_id: String?
    let link: String?
    let note: String?
}
