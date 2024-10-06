//
//  IxUser.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation

struct User: Decodable, Identifiable {
    let id: String
    let email: String
    let has_pro: Bool
    let creation_timestamp: Date
    let creation_source: CreationSource
    
    enum CreationSource: String, Decodable {
        case GOOGLE = "google"
        case APPLE = "apple"
        case FACEBOOK = "facebook"
        case NONE = "none"
    }
    
}
