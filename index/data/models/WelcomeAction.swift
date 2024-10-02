//
//  WelcomeAction.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation

struct WelcomeActionResponse: Decodable {
    let action: WelcomeAction
}

enum WelcomeAction: String, Decodable {
    case REGISTER = "register"
    case LOGIN = "login"
}
