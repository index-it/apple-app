//
//  UserCreationSource.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

public enum UserCreationSource: String, Codable, Sendable {
    case GOOGLE = "google"
    case APPLE = "apple"
    case FACEBOOK = "facebook"
    case NONE = "none"
}
