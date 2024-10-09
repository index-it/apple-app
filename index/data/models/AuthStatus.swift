//
//  AuthStatus.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

enum AuthStatus {
    case Loading;
    case Unauthenticated;
    case Authenticated(user: User);
}
