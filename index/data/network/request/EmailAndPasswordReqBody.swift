//
//  LoginRequestBody.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 03/10/24.
//

import Foundation

struct EmailAndPasswordReqBody: Encodable {
    let email: String
    let password: String
}
