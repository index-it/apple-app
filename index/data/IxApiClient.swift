//
//  IxApiClient.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation
import os

class IxApiClient {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: IxApiClient.self))
        
    private static let baseUrl = URL(string: "https://api.index-it.app")!
    
    func welcomeAction(email: String) async throws -> WelcomeAction {
        let url = Self.baseUrl
            .appendingPathComponent("/welcome-action")
            .appending(queryItems: [URLQueryItem(name: "email", value: email)])
        
        guard let (data, urlRes) = try? await URLSession.shared.data(from: url)
        else {
            throw IxApiClientError.Unknown
        }
        
        guard let res = urlRes as? HTTPURLResponse
        else {
            throw IxApiClientError.Unknown
        }
        
        if (res.statusCode != 200) {
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
        
        guard let welcomeAction = try? JSONDecoder().decode(WelcomeAction.self, from: data)
        else {
            Self.log.error("couldn't decode welcome action: \(String(data: data, encoding: .utf8) ?? "unparsable data received")")
            throw IxApiClientError.Unknown
        }
        
        return welcomeAction
    }
}
