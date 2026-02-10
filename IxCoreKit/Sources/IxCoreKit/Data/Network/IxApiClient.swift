//
//  IxApiClient.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 02/10/24.
//

import Foundation
import os

private let log = Logger.networkLogger

public final class IxApiClient: Sendable {
    private static let baseUrl = URL(string: "https://api.index-it.app")!

    private let cookieStorage: HTTPCookieStorage
    private let authChangeCallback: @Sendable (AuthStatus) -> Void

    /// Create a single URLSession instance to reuse
    private let urlSession: URLSession

    public init(
        cookieStorage: HTTPCookieStorage = IxCookieStorageProvider.get(),
        authChangeCallback: @Sendable @escaping (AuthStatus) -> Void
    ) {
        self.cookieStorage = cookieStorage
        self.authChangeCallback = authChangeCallback

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = self.cookieStorage
        urlSession = URLSession(configuration: configuration)

        initAuth()
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")!
        decoder.dateDecodingStrategy = .formatted(formatter)

        return decoder
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)

        return encoder
    }

    // MARK: - Authentication

    private func initAuth() {
        Task {
            do {
                let _ = try await me()
            } catch {}
        }
    }

    private func handleAuthenticationStatus(_ authenticationStatus: AuthStatus) {
        authChangeCallback(authenticationStatus)
    }

    /// gets the given welcome action for a user email
    ///
    /// - Returns: the `IxWelcomeAction`
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
    @Sendable public func welcomeAction(email: String) async throws -> WelcomeAction {
        let url = Self.baseUrl
            .appendingPathComponent("/welcome-action")
            .appending(queryItems: [URLQueryItem(name: "email", value: email)])

        let (data, urlRes) = try await urlSession.data(from: url)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            return try Self.decoder().decode(WelcomeActionResponse.self, from: data).action
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
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
    @Sendable public func register(email: String, password: String) async throws -> Bool {
        let url = Self.baseUrl.appendingPathComponent("/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try Self.encoder().encode(EmailAndPasswordReqBody(email: email, password: password))
        req.httpBody = body

        let (_, urlRes) = try await urlSession.data(for: req)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            return true
        case 201:
            return false
        case 400:
            throw IxApiClientError.emailOrPasswordFormatInvalid
        case 403:
            throw IxApiClientError.unusableEmail
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
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
    @Sendable public func sendVerificationEmail(email: String, password: String) async throws -> Bool {
        let url = Self.baseUrl.appendingPathComponent("/send-verification-email")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "email=\(email)&password=\(password)"
        req.httpBody = bodyString.data(using: .utf8)

        let (_, urlRes) = try await urlSession.data(for: req)
        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            return false
        case 201:
            return true
        case 403:
            throw IxApiClientError.unauthenticated
        case 429:
            throw IxApiClientError.tooManyVerificationEmails
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// Checks if the user's email has been verified.
    ///
    /// - Returns: `true` if the email is verified, `false` otherwise.
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated`: If the user is not authenticated.
    /// - `IxApiClientError.Unknown`: If an unknown error occurs.
    @Sendable public func isEmailVerified(email: String, password: String) async throws -> Bool {
        let url = Self.baseUrl.appendingPathComponent("/is-email-verified")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "email=\(email)&password=\(password)"
        req.httpBody = bodyString.data(using: .utf8)

        let (_, urlRes) = try await urlSession.data(for: req)
        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            return true
        case 403:
            throw IxApiClientError.unauthenticated
        case 404:
            return false
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// Sends an email to reset the password of a user with the specified email.
    ///
    /// ### Throws
    /// - `IxApiClientError.NotFound`: If the email does not exist.
    /// - `IxApiClientError.TooManyRequests`: If too many password reset requests have been sent.
    /// - `IxApiClientError.Unknown`: If an unknown error occurs.
    @Sendable public func passwordForgotten(email: String) async throws {
        let url = Self.baseUrl
            .appendingPathComponent("/password-forgotten")
            .appending(queryItems: [URLQueryItem(name: "email", value: email)])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (_, urlRes) = try await urlSession.data(for: req)
        let res = urlRes as! HTTPURLResponse

        if res.statusCode == 200 {
            return
        }

        switch res.statusCode {
        case 404:
            throw IxApiClientError.notFound(.selfUser)
        case 429:
            throw IxApiClientError.tooManyPasswordForgottenEmails
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// logs in the user with its email and password
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated` credentials invalid
    /// - `IxApiClientError.EmailNotVerified` user hasn't verified its email yet, required to login
    /// - `IxApiClientError.Unknown`
    @Sendable public func login(email: String, password: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try Self.encoder().encode(EmailAndPasswordReqBody(email: email, password: password))
        req.httpBody = body

        let (data, urlRes) = try await urlSession.data(for: req)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            let user = try User(from: Self.decoder().decode(NetworkUser.self, from: data))
            handleAuthenticationStatus(.authenticated(user: user))
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        case 405:
            throw IxApiClientError.emailNotVerified
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// logs in the user via google
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated` idToken invalid
    /// - `IxApiClientError.EmailNotVerifieid` user hasn't verified its email yet, required to login
    /// - `IxApiClientError.Unknown`
    @Sendable public func loginWithGoogle(idToken: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("login-with-google")
            .appending(queryItems: [URLQueryItem(name: "token_id", value: idToken)])
        let req = URLRequest(url: url)

        let (data, urlRes) = try await urlSession.data(for: req)
        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            let user = try User(from: Self.decoder().decode(NetworkUser.self, from: data))
            handleAuthenticationStatus(.authenticated(user: user))
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        case 405:
            throw IxApiClientError.emailNotVerified
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// logs in the user via apple
    ///
    /// ### Throws
    /// - `IxApiClientError.Unauthenticated` idToken invalid
    /// - `IxApiClientError.EmailNotVerifieid` user hasn't verified its email yet, required to login
    /// - `IxApiClientError.Unknown`
    @Sendable public func loginWithApple(idToken: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("login-with-apple")
            .appending(queryItems: [URLQueryItem(name: "token_id", value: idToken)])
        let req = URLRequest(url: url)

        let (data, urlRes) = try await urlSession.data(for: req)
        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            let user = try User(from: Self.decoder().decode(NetworkUser.self, from: data))
            handleAuthenticationStatus(.authenticated(user: user))
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        case 405:
            throw IxApiClientError.emailNotVerified
        default:
            log.error("received unexpected status code from server: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// Changes the password of the currently logged-in user.
    ///
    /// This does not invalidate the current session but invalidates all other active sessions.
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`: If the new password does not meet the required format.
    /// - `IxApiClientError.NotFound`: If the user is not found.
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    @Sendable public func changePassword(newPassword: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/me/password")

        var request = URLRequest(url: url)

        let body = ["password": newPassword]
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return // Password successfully changed.
        case 400:
            throw IxApiClientError.emailOrPasswordFormatInvalid
        case 404:
            throw IxApiClientError.notFound(.selfUser)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Deletes the currently logged-in account.
    ///
    /// **All data will be completely erased from the server.**
    ///
    /// ### Throws:
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    @Sendable public func deleteLoggedInUser() async throws {
        let url = Self.baseUrl.appendingPathComponent("/me")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200, 401:
            // Successful deletion or already unauthenticated; proceed as unauthenticated.
            handleAuthenticationStatus(.unauthenticated)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Sends the notification token of Firebase Cloud Messaging to the server.
    ///
    /// ### Throws:
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    @Sendable public func sendNotificationRegistrationToken(token: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/me/notifications/registration")
        let body = ["token": token]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return // Successfully sent the token.
        case 401:
            handleAuthenticationStatus(.unauthenticated)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// logs out the currently logged in user (if any)
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
    @Sendable public func logout() async throws {
        let url = Self.baseUrl.appendingPathComponent("/logout")

        let (_, urlRes) = try await urlSession.data(from: url)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            handleAuthenticationStatus(.unauthenticated)
        case 401:
            handleAuthenticationStatus(.unauthenticated)
        default:
            log.error("unexpected api response: \(res)")
            throw IxApiClientError.unknown
        }
    }

    // MARK: - User

    /// get the logged in user, uses the auth cookies stored in the device
    ///
    /// - Returns: the logged in `IxUser`
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
    /// - `IxApiClientError.Unauthenticated`
    @Sendable public func me() async throws -> User {
        let url = Self.baseUrl.appendingPathComponent("/me")

        let (data, urlRes) = try await urlSession.data(from: url)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            let user = try User(from: Self.decoder().decode(NetworkUser.self, from: data))
            handleAuthenticationStatus(.authenticated(user: user))
            return user
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        default:
            log.error("unexpected api response: \(res)")
            throw IxApiClientError.unknown
        }
    }

    @Sendable public func restorePurchases() async throws -> User {
        let url = Self.baseUrl.appendingPathComponent("/pro/subscription/restore")
        let (data, urlRes) = try await urlSession.data(from: url)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            let user = try User(from: Self.decoder().decode(NetworkUser.self, from: data))
            handleAuthenticationStatus(.authenticated(user: user))
            return user
        case 204:
            // nothing to do, user is already updated
            return try await me()
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        case 404:
            throw IxApiClientError.notFound(.proSubscription)
        default:
            log.error("unexpected api response: \(res)")
            throw IxApiClientError.unknown
        }
    }

    // MARK: - Lists

    /// Gets all the user lists
    /// - Returns: an array of `IxList`
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
    public func getLists() async throws -> [IxList] {
        let url = Self.baseUrl.appendingPathComponent("/lists")

        let (data, urlRes) = try await urlSession.data(from: url)

        let res = urlRes as! HTTPURLResponse

        switch res.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkList].self, from: data).map { networList in IxList(networkList: networList) }
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        default:
            log.error("unexpected api response: \(res)")
            throw IxApiClientError.unknown
        }
    }

    /// Creates a new list with the given name, emoji, and color.
    ///
    /// The user needs a Pro subscription to create a public list.
    ///
    /// - Returns: The newly created list as an `IxList`.
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`: If the parameters are invalid
    /// - `IxApiClientError.ProRequired`
    /// - `IxApiClientError.Unknown`
    @Sendable public func createList(name: String, icon: String, color: String, archived: Bool, is_public: Bool) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ListCreateOrEditReqBody(name: name, icon: icon, color: color, archived: archived, isPublic: is_public)
        request.httpBody = try Self.encoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            let networkList = try Self.decoder().decode(NetworkList.self, from: data)
            return IxList(networkList: networkList)
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            handleAuthenticationStatus(.unauthenticated)
            throw IxApiClientError.unauthenticated
        case 402:
            if is_public {
                throw IxApiClientError.proRequired(.public_list)
            } else {
                throw IxApiClientError.proRequired(.unlimited_lists)
            }
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Retrieves a single list by its identifier.
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermissions`: If the user does not have access to the list.
    /// - `IxApiClientError.NotFound`: If the list with the specified ID is not found.
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    @Sendable public func getList(id: String) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)")
        let (data, response) = try await urlSession.data(from: url)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            let networkList = try Self.decoder().decode(NetworkList.self, from: data)
            return IxList(networkList: networkList)
        case 403:
            throw IxApiClientError.missingPermission(.viewer)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Edits a list by its identifier with the provided name, emoji, color, and public status.
    ///
    /// The user needs pro to make the list public.
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`: If the request body is invalid.
    /// - `IxApiClientError.Unauthenticated`: If the user is not authenticated.
    /// - `IxApiClientError.ProRequired`: If the user needs a Pro feature to make the list public.
    /// - `IxApiClientError.MissingPermission`: If the user lacks permission to edit the list.
    /// - `IxApiClientError.NotFound`: If the list with the specified ID is not found.
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    @Sendable public func editList(id: String, name: String, icon: String, color: String, archived: Bool, is_public: Bool) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)")
        let requestBody = ListCreateOrEditReqBody(name: name, icon: icon, color: color, archived: archived, isPublic: is_public)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            let networkList = try Self.decoder().decode(NetworkList.self, from: data)
            return IxList(networkList: networkList)
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            throw IxApiClientError.unauthenticated
        case 402:
            throw IxApiClientError.proRequired(.public_list)
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Deletes a list via its id
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.MissingPermission` List owner required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func deleteList(id: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.owner)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    // MARK: - List access

    /// Gets all the users that have access to the list with the specified id
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.MissingPermission` List owner required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func getListUsersWithAccess(id: String) async throws -> [IxListSingleUserAccessInfo] {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)/access/users")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([IxListSingleUserAccessInfo].self, from: data)
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.owner)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Leaves a list with the specified id if the logged in user is either a viewer or editor
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData` Bad request
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func leaveList(id: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)/access/leave")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return
        case 401:
            throw IxApiClientError.unauthenticated
        case 404:
            throw IxApiClientError.notFound(.list)
        case 405:
            throw IxApiClientError.invalidData
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Gives a user access to a list
    ///
    /// - Returns: `null` if the user was invited, the list if they already accepted a previous invitation and their permissions are changed
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData` Cannot invite self
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func inviteUserToList(listId: String, email: String, editor: Bool) async throws -> IxList? {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access/users")
        let requestBody = ListGiveUserAccessReqBody(email: email, editor: editor)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxList(networkList: Self.decoder().decode(NetworkList.self, from: data))
        case 201:
            return nil
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.owner)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Removes access to the list from a user
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func revokeListAccessFromUser(listId: String, userId: String) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access/users")
        let requestBody = ListRemoveUserAccessReqBody(userId: userId)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxList(networkList: Self.decoder().decode(NetworkList.self, from: data))
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.owner)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Gets all the active user-agnostic invites for a list
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func getListInvites(listId: String) async throws -> [IxListInvite] {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access/invites")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkListInvite].self, from: data).map { IxListInvite(networkListInvite: $0) }
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.owner)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Create a list invite
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    @Sendable public func createListInvite(
        listId: String,
        editor: Bool,
        maxUsages: Int?,
        expiresAt: Date?,
        description: String?
    ) async throws -> IxListInvite {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access/invites")
        let requestBody = ListInviteCreateReqBody(
            editor: editor,
            maxUsages: maxUsages,
            expiresAt: expiresAt,
            description: description
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListInvite(networkListInvite: Self.decoder().decode(NetworkListInvite.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Deletes a list invite, effectively making it inactive
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.Unknown` Unknown error
    @Sendable public func deleteListInvite(
        listId: String,
        inviteId: String
    ) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access/invites/\(inviteId)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            break
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            break
        default:
            throw IxApiClientError.unknown
        }
    }

    // MARK: - List categories

    /// Gets all the categories of a list
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Viewer required
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func getListCategories(listId: String) async throws -> [IxListCategory] {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkListCategory].self, from: data).map { IxListCategory(networkListCategory: $0) }
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.viewer)
        case 404:
            throw IxApiClientError.notFound(.category)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Gets a specific category via the list and category id
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` Category or list not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func getCategory(listId: String, categoryId: String) async throws -> IxListCategory {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories/\(categoryId)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListCategory(networkListCategory: Self.decoder().decode(NetworkListCategory.self, from: data))
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.viewer)
        case 404:
            throw IxApiClientError.notFound(.category)
        default:
            throw IxApiClientError.unknown
        }
    }

    @Sendable public func createCategory(listId: String, name: String, color: String?) async throws -> IxListCategory {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories")
        let requestBody = ListCategoryCreateOrEditReqBody(name: name, color: color)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListCategory(networkListCategory: Self.decoder().decode(NetworkListCategory.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.list)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Edits a list category
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData` Invalid name or color
    /// - `IxApiClientError.MissingPermission` Editor required
    /// - `IxApiClientError.NotFound` List or category not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func updateListCategory(listId: String, categoryId: String, name: String, color: String?) async throws -> IxListCategory {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories/\(categoryId)")
        let requestBody = ListCategoryCreateOrEditReqBody(name: name, color: color)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListCategory(networkListCategory: Self.decoder().decode(NetworkListCategory.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.category)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Deletes a list category
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Editor required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func deleteListCategory(listId: String, categoryId: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories/\(categoryId)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            break // Deletion successful, no content to return
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            break // Ignore this error
        default:
            throw IxApiClientError.unknown
        }
    }

    // MARK: - List items

    /// Gets all the items of a list
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Permission required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func getListItems(listId: String, completed: Bool? = nil) async throws -> [IxListItem] {
        var urlComponents = URLComponents(string: "\(Self.baseUrl)/lists/\(listId)/items")!
        var queryItems = [URLQueryItem]()

        if let completed = completed {
            queryItems.append(URLQueryItem(name: "completed", value: "\(completed)"))
        }
        urlComponents.queryItems = queryItems

        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkListItem].self, from: data).map { IxListItem(networkListItem: $0) }
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.viewer)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Gets a single list item via the [itemId]
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Permission required
    /// - `IxApiClientError.NotFound` The list or item doesn't exist
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func getListItem(listId: String, itemId: String) async throws -> IxListItem {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListItem(networkListItem: Self.decoder().decode(NetworkListItem.self, from: data))
        case 401:
            throw IxApiClientError.unauthenticated
        case 403:
            throw IxApiClientError.missingPermission(.viewer)
        case 404:
            throw IxApiClientError.notFound(.item)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Creates a new list item
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.Unknown` Unknown error
    @Sendable public func createListItem(listId: String, categoryId: String?, name: String, link: String?, note: String?) async throws -> IxListItem {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ListItemCreateOrEditReqBody(name: name, categoryId: categoryId, link: link, note: note)
        request.httpBody = try Self.encoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListItem(networkListItem: Self.decoder().decode(NetworkListItem.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Edits a list item
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData` Invalid `name`
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.NotFound` List or item not found
    /// - `IxApiClientError.Unknown` Unknown error
    @Sendable public func updateListItem(listId: String, itemId: String, name: String, categoryId: String?, link: String?, note: String?) async throws -> IxListItem {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Setting the body for the request
        let body = ListItemCreateOrEditReqBody(name: name, categoryId: categoryId, link: link, note: note)
        request.httpBody = try Self.encoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListItem(networkListItem: Self.decoder().decode(NetworkListItem.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.item)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Completes or un-completes an item
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.NotFound` List or item not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    @Sendable public func setListItemCompletion(listId: String, itemId: String, completed: Bool) async throws -> IxListItem {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/items/\(itemId)/completion")
            .appending(queryItems: [URLQueryItem(name: "completed", value: "\(completed)")])

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxListItem(networkListItem: Self.decoder().decode(NetworkListItem.self, from: data))
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.item)
        default:
            throw IxApiClientError.unknown
        }
    }

    @Sendable public func setListItemsCompletion(listId: String, itemIds: [String], completed: Bool) async throws -> [IxListItem] {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/items/completion")
            .appending(queryItems: [URLQueryItem(name: "completed", value: "\(completed)")])

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder().encode(itemIds)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkListItem].self, from: data).map { IxListItem(networkListItem: $0) }
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.item)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Move list items between lists
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.NotFound` List or item not found
    /// - `IxApiClientError.Unknown` Unknown error
    @Sendable public func moveListItems(listId: String, itemIds: [String], moveListId: String?, moveCategoryId: String?) async throws -> [IxListItem] {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items/move")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Setting the body for the request
        let body = ListItemsMoveReqBody(ids: itemIds, listId: moveListId, categoryId: moveCategoryId)
        request.httpBody = try Self.encoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkListItem].self, from: data).map { IxListItem(networkListItem: $0) }
        case 400:
            throw IxApiClientError.invalidData
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        case 404:
            throw IxApiClientError.notFound(.item)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Deletes a list item
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.Unknown` Unknown error
    @Sendable public func deleteListItem(listId: String, itemId: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/items/\(itemId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            break // Item successfully deleted
        case 403:
            throw IxApiClientError.missingPermission(.editor)
        default:
            throw IxApiClientError.unknown
        }
    }

    // MARK: - Tasks

    /// Gets all the tasks of the user
    ///
    /// ### Throws:
    /// - `IxApiClientError.Unknown`
    ///
    @Sendable public func getTasks(completed: Bool? = nil) async throws -> [IxTask] {
        var urlComponents = URLComponents(string: "\(Self.baseUrl)/tasks")!
        var queryItems = [URLQueryItem]()

        if let completed = completed {
            queryItems.append(URLQueryItem(name: "completed", value: "\(completed)"))
        }
        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkTask].self, from: data).map { IxTask(networkTask: $0) }
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Gets a single task via the [taskId]
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    ///
    @Sendable public func getTask(taskId: String) async throws -> IxTask {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxTask(networkTask: Self.decoder().decode(NetworkTask.self, from: data))
        case 404:
            throw IxApiClientError.notFound(.task)
        default:
            throw IxApiClientError.unknown
        }
    }

    @Sendable public func getTasksConnectedItemsData(completed: Bool? = false) async throws -> (items: [IxListItem], categories: [IxListCategory], lists: [IxList]) {
        var urlComponents = URLComponents(string: "\(Self.baseUrl)/tasks/connected-items")!
        var queryItems = [URLQueryItem]()

        if let completed = completed {
            queryItems.append(URLQueryItem(name: "completed", value: "\(completed)"))
        }
        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            let itemsData = try Self.decoder().decode(NetworkTaskConnectedItems.self, from: data)
            return (
                itemsData.items.map { IxListItem(networkListItem: $0) },
                itemsData.categories.map { IxListCategory(networkListCategory: $0) },
                itemsData.lists.map { IxList(networkList: $0) }
            )
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Creates a new task
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`
    /// - `IxApiClientError.ProRequired`
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    @Sendable public func createTask(name: String, description: String?, dueDate: Date?, rrule: String?, reminders: [IxTaskReminder], subtasks: [IxSubTask], priority: Int?, itemId: String?) async throws -> IxTask {
        let url = URL(string: "\(Self.baseUrl)/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TaskCreateOrEditReqBody(
            name: name,
            description: description,
            itemId: itemId,
            subtasks: subtasks.map { NetworkSubTask(name: $0.name, completed: $0.completed) },
            dueDate: dueDate,
            rrule: rrule,
            priority: priority,
            reminders: reminders.map { NetworkTaskReminder(daysBefore: $0.daysBefore, timeOffset: $0.timeOffset) }
        )

        request.httpBody = try Self.encoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxTask(networkTask: Self.decoder().decode(NetworkTask.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 402:
            throw IxApiClientError.proRequired(.unlimited_task_reminders)
        case 404:
            throw IxApiClientError.notFound(.item)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Edits an existing task
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    @Sendable public func editTask(taskId: String, name: String, description: String?, dueDate: Date?, rrule: String?, reminders: [IxTaskReminder], subtasks: [IxSubTask], priority: Int?, itemId: String?) async throws -> IxTask {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TaskCreateOrEditReqBody(
            name: name,
            description: description,
            itemId: itemId,
            subtasks: subtasks.map { NetworkSubTask(name: $0.name, completed: $0.completed) },
            dueDate: dueDate,
            rrule: rrule,
            priority: priority,
            reminders: reminders.map { NetworkTaskReminder(daysBefore: $0.daysBefore, timeOffset: $0.timeOffset) }
        )
        request.httpBody = try Self.encoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxTask(networkTask: Self.decoder().decode(NetworkTask.self, from: data))
        case 400:
            throw IxApiClientError.invalidData
        case 404:
            throw IxApiClientError.notFound(.task)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Sets the completion status of a task
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    @Sendable public func setTaskCompletion(taskId: String, completed: Bool) async throws -> IxTask {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)/completion")
            .appending(queryItems: [URLQueryItem(name: "completed", value: "\(completed)")])

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return try IxTask(networkTask: Self.decoder().decode(NetworkTask.self, from: data))
        case 404:
            throw IxApiClientError.notFound(.task)
        default:
            throw IxApiClientError.unknown
        }
    }

    /// Deletes a task via the [taskId]
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    @Sendable public func deleteTask(taskId: String, all: Bool? = nil) async throws {
        var urlComponents = URLComponents(string: "\(Self.baseUrl)/tasks/\(taskId)")!

        if let all = all {
            var queryItems = [URLQueryItem]()
            queryItems.append(URLQueryItem(name: "all", value: "\(all)"))
            urlComponents.queryItems = queryItems
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200:
            return
        case 404:
            throw IxApiClientError.notFound(.task)
        default:
            throw IxApiClientError.unknown
        }
    }
}
