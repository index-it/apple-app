//
//  ListCreateOrEditReqBody.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/11/24.
//

struct ListCreateOrEditReqBody: Codable {
    let name: String
    let icon: String
    let color: String
    let archived: Bool
    let is_public: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case color
        case archived
        case is_public = "public"
    }
}
