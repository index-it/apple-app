//
//  AuthStatus.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

public enum AuthStatus: Sendable, Equatable {
    case loading
    case unauthenticated
    case authenticated(user: User)

    public static func == (lhs: AuthStatus, rhs: AuthStatus) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true

        case (.unauthenticated, .unauthenticated):
            return true

        case let (.authenticated(lhsUser), .authenticated(rhsUser)):
            return lhsUser.id == rhsUser.id

        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .loading:
            return "loading"
        case .unauthenticated:
            return "unauthenticated"
        case .authenticated(let user):
            return "authenticated(\(user))"
        }
    }
}
