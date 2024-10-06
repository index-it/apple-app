//
//  IxApiClient.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation
import os

class IxApiClient: ObservableObject {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: IxApiClient.self))
    private static let baseUrl = URL(string: "https://api.index-it.app")!
    
    @Published var authenticationStatus = AuthenticationStatus.Loading
    
    init() {
        Task {
            do {
                _ = try await me()
            } catch let error {
                Self.log.warning("failed fetching self user: \(error)")
            }
        }
    }
    
    @MainActor
    private func setAuthenticationStatus(authenticationStatus: AuthenticationStatus) {
        self.authenticationStatus = authenticationStatus
    }
    
    /// gets the given welcome action for a user email
    ///
    /// - Parameters:
    ///     - email: the user email
    ///
    /// - Throws:
    ///     - `IxApiError.Unknown`
    ///
    /// - Returns: the `IxWelcomeAction`
    func welcomeAction(email: String) async throws -> WelcomeAction {
        let url = Self.baseUrl
            .appendingPathComponent("/welcome-action")
            .appending(queryItems: [URLQueryItem(name: "email", value: email)])
        
        let (data, urlRes) = try await URLSession.shared.data(from: url)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return try JSONDecoder().decode(WelcomeActionResponse.self, from: data).action
        default:
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    ///
    func login(email: String, password: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONEncoder().encode(EmailAndPasswordLoginRequestBody(email: email, password: password))
        req.httpBody = body
        
        let (data, urlRes) = try await URLSession.shared.data(for: req)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let user = try JSONDecoder().decode(User.self, from: data)
            await setAuthenticationStatus(authenticationStatus: .Authenticated(user: user))
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        case 405:
            throw IxApiClientError.EmailNotVerified
        default:
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    /// get the logged in user, uses the auth cookies stored in the device
    ///
    /// - Returns: the logged in `IxUser`
    ///
    /// - Throws
    ///     - `IxApiClientError.Unknown`
    ///     - `IxApiClientError.Unauthenticated`
    func me() async throws -> User {
        let url = Self.baseUrl.appendingPathComponent("/me")
        
        let (data, urlRes) = try await URLSession.shared.data(from: url)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let user = try JSONDecoder().decode(User.self, from: data)
            await setAuthenticationStatus(authenticationStatus: .Authenticated(user: user))
            return user
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            Self.log.error("unexpected api response: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    func logout() async throws {
        let url = Self.baseUrl.appendingPathComponent("/logout")
        
        let (_, urlRes) = try await URLSession.shared.data(from: url)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
        default:
            Self.log.error("unexpected api response: \(res)")
            throw IxApiClientError.Unknown
        }
    }
}
