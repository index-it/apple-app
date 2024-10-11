//
//  AuthNavigationRoute.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/10/24.
//

import Foundation

enum AuthNavigationRoute: Hashable {
    case PasswordLogin(email: String);
    case PasswordRegister(email: String);
    case EmailVerification(email: String, password: String);
}
