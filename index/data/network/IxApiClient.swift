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
    
    @Published var authenticationStatus = AuthStatus.Loading
    
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
    private func setAuthenticationStatus(authenticationStatus: AuthStatus) {
        self.authenticationStatus = authenticationStatus
    }
    
    /*
     AUTHENTICATION
     */
    
    /// gets the given welcome action for a user email
    ///
    /// - Returns: the `IxWelcomeAction`
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
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
    
    /// register a new user with its email and password
    ///
    /// - Returns: true if the user has been registered and a verification email has been sent, false if user has been registered but the verification email **hasn't** been sent because of some rate limits
    ///
    /// ### Throws
    /// - `IxApiClientError.EmailOrPasswordFormatInvalid`
    /// - `IxApiClientError.UnusableEmail`
    /// - `IxApiClientError.Unknown`
    func register(email: String, password: String) async throws -> Bool {
        let url = Self.baseUrl.appendingPathComponent("/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONEncoder().encode(EmailAndPasswordRequestBody(email: email, password: password))
        req.httpBody = body
        
        let (_, urlRes) = try await URLSession.shared.data(for: req)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return true
        case 201:
            return false
        case 400:
            throw IxApiClientError.EmailOrPasswordFormatInvalid
        case 403:
            throw IxApiClientError.UnusableEmail
        default:
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    /// Sends an account verification email to the specified email.
    /// Requires the password to be provided too.
    ///
    /// - Returns: `true` if a verification email has been sent, `false` if the user is already verified.
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated`: If the user is not authenticated.
    /// - `IxApiClientError.TooManyRequests`: If too many verification email requests have been sent.
    /// - `IxApiClientError.Unknown`: If an unknown error occurs.
    func sendVerificationEmail(email: String, password: String) async throws -> Bool {
        let url = Self.baseUrl.appendingPathComponent("/send-verification-email")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "email=\(email)&password=\(password)"
        req.httpBody = bodyString.data(using: .utf8)
        
        let (_, urlRes) = try await URLSession.shared.data(for: req)
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return false
        case 201:
            return true
        case 403:
            throw IxApiClientError.Unauthenticated
        case 429:
            throw IxApiClientError.TooManyRequests
        default:
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    /// Checks if the user's email has been verified.
    ///
    /// - Returns: `true` if the email is verified, `false` otherwise.
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated`: If the user is not authenticated.
    /// - `IxApiClientError.Unknown`: If an unknown error occurs.
    func isEmailVerified(email: String, password: String) async throws -> Bool {
        let url = Self.baseUrl.appendingPathComponent("/is-email-verified")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "email=\(email)&password=\(password)"
        req.httpBody = bodyString.data(using: .utf8)
        
        let (_, urlRes) = try await URLSession.shared.data(for: req)
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            return true
        case 403:
            throw IxApiClientError.Unauthenticated
        case 404:
            return false
        default:
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    /// Sends an email to reset the password of a user with the specified email.
    ///
    /// ### Throws
    /// - `IxApiClientError.UserNotFound`: If the email does not exist.
    /// - `IxApiClientError.TooManyRequests`: If too many password reset requests have been sent.
    /// - `IxApiClientError.Unknown`: If an unknown error occurs.
    func passwordForgotten(email: String) async throws {
        let url = Self.baseUrl
            .appendingPathComponent("/password-forgotten")
            .appending(queryItems: [URLQueryItem(name: "email", value: email)])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        let (_, urlRes) = try await URLSession.shared.data(for: req)
        let res = urlRes as! HTTPURLResponse
        
        if (res.statusCode == 200) {
            return
        }
        
        switch res.statusCode {
        case 404:
            throw IxApiClientError.UserNotFound
        case 429:
            throw IxApiClientError.TooManyRequests
        default:
            Self.log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.Unknown
        }
    }
    
    /// logs in the user with its email and password
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated` credentials invalid
    /// - `IxApiClientError.EmailNotVerified` user hasn't verified its email yet, required to login
    /// - `IxApiClientError.Unknown`
    func login(email: String, password: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONEncoder().encode(EmailAndPasswordRequestBody(email: email, password: password))
        req.httpBody = body
        
        let (data, urlRes) = try await URLSession.shared.data(for: req)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let user = User(from: try JSONDecoder().decode(NetworkUser.self, from: data))
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
    
    /// logs in the user via google
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated` idToken invalid
    /// - `IxApiClientError.EmailNotVerifieid` user hasn't verified its email yet, required to login
    /// - `IxApiClientError.Unknown`
    func loginWithGoogle(idToken: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("login-with-google")
            .appending(queryItems: [URLQueryItem(name: "token_id", value: idToken)])
        let req = URLRequest(url: url)
        
        let (data, urlRes) = try await URLSession.shared.data(for: req)
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let user = User(from: try JSONDecoder().decode(NetworkUser.self, from: data))
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
    
    /// logs in the user via apple
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated` idToken invalid
    /// - `IxApiClientError.EmailNotVerifieid` user hasn't verified its email yet, required to login
    /// - `IxApiClientError.Unknown`
    func loginWithApple(idToken: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("login-with-apple")
            .appending(queryItems: [URLQueryItem(name: "token_id", value: idToken)])
        let req = URLRequest(url: url)
        
        let (data, urlRes) = try await URLSession.shared.data(for: req)
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let user = User(from: try JSONDecoder().decode(NetworkUser.self, from: data))
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
    
    
    /// logs out the currently logged in user (if any)
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
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
    
    
    /*
     USER
     */
    
    /// get the logged in user, uses the auth cookies stored in the device
    ///
    /// - Returns: the logged in `IxUser`
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
    /// - `IxApiClientError.Unauthenticated`
    func me() async throws -> User {
        let url = Self.baseUrl.appendingPathComponent("/me")
        
        let (data, urlRes) = try await URLSession.shared.data(from: url)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let user = User(from: try JSONDecoder().decode(NetworkUser.self, from: data))
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
}
