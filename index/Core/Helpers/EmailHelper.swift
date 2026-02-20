//
//  EmailHelper.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 20/02/26.
//

import SwiftUI

enum EmailHelper {
    public static func promptEmail(
        email: String = "contact@index-it.app",
        subject: String? = nil,
    ) {
        let encodedSubject = subject?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)")!

        if UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL)
        }
    }
}
