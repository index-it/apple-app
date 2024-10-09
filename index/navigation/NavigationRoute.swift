//
//  NavigationRoute.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation

enum NavigationRoute: Hashable {
    // authentication
    case EmailLogin;
    case PasswordLogin(email: String);
    case PasswordRegister(email: String);
    case EmailVerification(email: String, password: String);
}
