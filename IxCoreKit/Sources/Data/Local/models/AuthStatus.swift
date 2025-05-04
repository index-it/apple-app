//
//  AuthStatus.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

public enum AuthStatus: Sendable, Equatable {
    case loading;
    case unauthenticated;
    case authenticated(user: User);
}
