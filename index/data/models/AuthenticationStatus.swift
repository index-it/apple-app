//
//  AuthenticationStatus.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/10/24.
//

enum AuthenticationStatus {
    case Loading;
    case Unauthenticated;
    case Authenticated(user: User);
}
