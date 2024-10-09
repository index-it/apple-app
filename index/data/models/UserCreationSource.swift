//
//  UserCreationSource.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

enum UserCreationSource: String, Codable {
    case GOOGLE = "google"
    case APPLE = "apple"
    case FACEBOOK = "facebook"
    case NONE = "none"
}
