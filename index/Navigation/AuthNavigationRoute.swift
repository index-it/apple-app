//
//  AuthNavigationRoute.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/10/24.
//

import Foundation

enum AuthNavigationRoute: Hashable {
    case passwordLogin(email: String)
    case passwordRegister(email: String)
    case emailVerification(email: String, password: String, verificationEmailSent: Bool)
}
