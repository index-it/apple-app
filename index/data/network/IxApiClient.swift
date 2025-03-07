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
    
    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return decoder
    }
    
    @MainActor
    private func setAuthenticationStatus(authenticationStatus: AuthStatus) {
        self.authenticationStatus = authenticationStatus
    }
    
    // MARK: - Authentication
    
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
        let body = try JSONEncoder().encode(EmailAndPasswordReqBody(email: email, password: password))
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
            throw IxApiClientError.TooManyVerificationEmails
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
    /// - `IxApiClientError.NotFound`: If the email does not exist.
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
            throw IxApiClientError.NotFound(.self_user)
        case 429:
            throw IxApiClientError.TooManyPasswordForgottenEmails
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
        let body = try JSONEncoder().encode(EmailAndPasswordReqBody(email: email, password: password))
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
    
    /// Changes the password of the currently logged-in user.
    ///
    /// This does not invalidate the current session but invalidates all other active sessions.
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`: If the new password does not meet the required format.
    /// - `IxApiClientError.NotFound`: If the user is not found.
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    func changePassword(newPassword: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/me/password")
        
        var request = URLRequest(url: url)
        
        let body = ["password": newPassword]
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return // Password successfully changed.
        case 400:
            throw IxApiClientError.EmailOrPasswordFormatInvalid
        case 404:
            throw IxApiClientError.NotFound(.self_user)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Deletes the currently logged-in account.
    ///
    /// **All data will be completely erased from the server.**
    ///
    /// ### Throws:
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    func deleteLoggedInUser() async throws {
        let url = Self.baseUrl.appendingPathComponent("/me")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200, 401:
            // Successful deletion or already unauthenticated; proceed as unauthenticated.
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Sends the notification token of Firebase Cloud Messaging to the server.
    ///
    /// ### Throws:
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    func sendNotificationRegistrationToken(token: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/me/notifications/register")
        let body = ["token": token]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return // Successfully sent the token.
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
        default:
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
    
    
    // MARK: - User
    
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
    
    
    // MARK: - Lists
    
    /// Gets all the user lists
    /// - Returns: an array of `IxList`
    ///
    /// ### Throws
    /// - `IxApiClientError.Unknown`
    func getLists() async throws -> [IxList] {
        let url = Self.baseUrl.appendingPathComponent("/lists")
        
        let (data, urlRes) = try await URLSession.shared.data(from: url)
        
        let res = urlRes as! HTTPURLResponse
        
        switch res.statusCode {
        case 200:
            let lists = try JSONDecoder().decode([NetworkList].self, from: data).map { networList in IxList(networkList: networList) }
            return lists
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            Self.log.error("unexpected api response: \(res)")
            throw IxApiClientError.Unknown
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
    func createList(name: String, icon: String, color: String, is_public: Bool) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ListCreateOrEditReqBody(name: name, icon: icon, color: color, is_public: is_public)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            let networkList = try JSONDecoder().decode(NetworkList.self, from: data)
            return IxList(networkList: networkList)
        case 400:
            throw IxApiClientError.InvalidData
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        case 402:
            if is_public {
                throw IxApiClientError.ProRequired(.public_list)
            } else {
                throw IxApiClientError.ProRequired(.unlimited_lists)
            }
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Retrieves a single list by its identifier.
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermissions`: If the user does not have access to the list.
    /// - `IxApiClientError.NotFound`: If the list with the specified ID is not found.
    /// - `IxApiClientError.Unknown`: For unexpected errors.
    func getList(id: String) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            let networkList = try JSONDecoder().decode(NetworkList.self, from: data)
            return IxList(networkList: networkList)
        case 403:
            throw IxApiClientError.MissingPermission(.list_viewer)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
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
    func editList(id: String, name: String, icon: String, color: String, is_public: Bool) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)")
        let requestBody = ListCreateOrEditReqBody(name: name, icon: icon, color: color, is_public: is_public)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            let networkList = try JSONDecoder().decode(NetworkList.self, from: data)
            return IxList(networkList: networkList)
        case 400:
            throw IxApiClientError.InvalidData
        case 401:
            throw IxApiClientError.Unauthenticated
        case 402:
            throw IxApiClientError.ProRequired(.public_list)
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Deletes a list via its id
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.MissingPermission` List owner required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func deleteList(id: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_owner)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
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
    func getListUsersWithAccess(id: String) async throws -> [IxListSingleUserAccessInfo] {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)/access/users")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([IxListSingleUserAccessInfo].self, from: data)
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_owner)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Leaves a list with the specified id if the logged in user is either a viewer or editor
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData` Bad request
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func leaveList(id: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(id)/access/leave")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 401:
            throw IxApiClientError.Unauthenticated
        case 404:
            throw IxApiClientError.NotFound(.list)
        case 405:
            throw IxApiClientError.InvalidData
        default:
            throw IxApiClientError.Unknown
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
    func inviteUserToList(listId: String, email: String, editor: Bool) async throws -> IxList? {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access")
        let requestBody = ListGiveUserAccessReqBody(email: email, editor: editor)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxList(networkList: try JSONDecoder().decode(NetworkList.self, from: data))
        case 201:
            return nil
        case 400:
            throw IxApiClientError.InvalidData
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_owner)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Removes access to the list from a user
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` List not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func revokeListAccessFromUser(listId: String, userId: String) async throws -> IxList {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/access")
        let requestBody = ListRemoveUserAccessReqBody(user_id: userId)
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxList(networkList: try JSONDecoder().decode(NetworkList.self, from: data))
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_owner)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
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
    func getListCategories(listId: String) async throws -> [IxListCategory] {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([NetworkListCategory].self, from: data).map { IxListCategory(networkListCategory: $0) }
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_viewer)
        case 404:
            throw IxApiClientError.NotFound(.category)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Gets a specific category via the list and category id
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Owner required
    /// - `IxApiClientError.NotFound` Category or list not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func getCategory(listId: String, categoryId: String) async throws -> IxListCategory {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories/\(categoryId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxListCategory(networkListCategory: try JSONDecoder().decode(NetworkListCategory.self, from: data))
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_viewer)
        case 404:
            throw IxApiClientError.NotFound(.category)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    func createCategory(listId: String, name: String, color: String) async throws -> IxListCategory {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories")
        let requestBody = ListCategoryCreateOrEditReqBody(name: name, color: color)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxListCategory(networkListCategory: try JSONDecoder().decode(NetworkListCategory.self, from: data))
        case 400:
            throw IxApiClientError.InvalidData
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        case 404:
            throw IxApiClientError.NotFound(.list)
        default:
            throw IxApiClientError.Unknown
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
    func updateListCategory(listId: String, categoryId: String, name: String, color: String) async throws -> IxListCategory {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories/\(categoryId)")
        let requestBody = ListCategoryCreateOrEditReqBody(name: name, color: color)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxListCategory(networkListCategory: try JSONDecoder().decode(NetworkListCategory.self, from: data))
        case 400:
            throw IxApiClientError.InvalidData
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        case 404:
            throw IxApiClientError.NotFound(.category)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Deletes a list category
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Editor required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func deleteListCategory(listId: String, categoryId: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/categories/\(categoryId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            break // Deletion successful, no content to return
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        case 404:
            break // Ignore this error
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    
    // MARK: - List items
    
    /// Gets all the items of a list
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Permission required
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func getListItems(listId: String, completed: Bool? = nil) async throws -> [IxListItem] {
        var urlComponents = URLComponents(string: "\(Self.baseUrl)/lists/\(listId)/items")!
        var queryItems = [URLQueryItem]()
        
        if let completed = completed {
            queryItems.append(URLQueryItem(name: "completed", value: "\(completed)"))
        }
        urlComponents.queryItems = queryItems
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([NetworkListItem].self, from: data).map { IxListItem(networkListItem: $0) }
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_viewer)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Gets a single list item via the [itemId]
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` Permission required
    /// - `IxApiClientError.NotFound` The list or item doesn't exist
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func getListItem(listId: String, itemId: String) async throws -> IxListItem {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxListItem(networkListItem: try JSONDecoder().decode(NetworkListItem.self, from: data))
        case 401:
            throw IxApiClientError.Unauthenticated
        case 403:
            throw IxApiClientError.MissingPermission(.list_viewer)
        case 404:
            throw IxApiClientError.NotFound(.item)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Creates a new list item
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.Unknown` Unknown error
    func createListItem(listId: String, categoryId: String?, name: String, link: String?, note: String?) async throws -> IxListItem {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ListItemCreateOrEditReqBody(name: name, category_id: categoryId, link: link, note: note)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        
        switch httpResponse.statusCode {
        case 200:
            return IxListItem(networkListItem: try JSONDecoder().decode(NetworkListItem.self, from: data))
        case 400:
            throw IxApiClientError.InvalidData
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Edits a list item
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData` Invalid `name`
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.NotFound` List or item not found
    /// - `IxApiClientError.Unknown` Unknown error
    func updateListItem(listId: String, itemId: String, name: String, categoryId: String?, link: String?, note: String?) async throws -> IxListItem {
        let url = URL(string: "\(Self.baseUrl)/lists/\(listId)/items/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Setting the body for the request
        let body = ListItemCreateOrEditReqBody(name: name, category_id: categoryId, link: link, note: note)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxListItem(networkListItem: try JSONDecoder().decode(NetworkListItem.self, from: data))
        case 400:
            throw IxApiClientError.InvalidData
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        case 404:
            throw IxApiClientError.NotFound(.item)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Completes or un-completes an item
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.NotFound` List or item not found
    /// - `IxApiClientError.Unknown` Unknown error
    ///
    func setListItemCompletion(listId: String, itemId: String, completed: Bool) async throws -> IxListItem {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/items/\(itemId)/completion")
            .appending(queryItems: [URLQueryItem(name: "completed", value: "\(completed)")])
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxListItem(networkListItem: try JSONDecoder().decode(NetworkListItem.self, from: data))
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        case 404:
            throw IxApiClientError.NotFound(.item)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Deletes a list item
    ///
    /// ### Throws:
    /// - `IxApiClientError.MissingPermission` List editor permissions required
    /// - `IxApiClientError.Unknown` Unknown error
    func deleteListItem(listId: String, itemId: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/lists/\(listId)/items/\(itemId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            break // Item successfully deleted
        case 403:
            throw IxApiClientError.MissingPermission(.list_editor)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    // MARK: - Tasks
    
    /// Gets all the tasks of the user
    ///
    /// ### Throws:
    /// - `IxApiClientError.Unknown`
    ///
    func getTasks(completed: Bool? = nil) async throws -> [IxTask] {
        var urlComponents = URLComponents(string: "\(Self.baseUrl)/tasks")!
        var queryItems = [URLQueryItem]()
        
        if let completed = completed {
            queryItems.append(URLQueryItem(name: "completed", value: "\(completed)"))
        }
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try Self.decoder().decode([NetworkTask].self, from: data).map { IxTask(networkTask: $0) }
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Gets a single task via the [taskId]
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    ///
    func getTask(taskId: String) async throws -> IxTask {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxTask(networkTask: try Self.decoder().decode(NetworkTask.self, from: data))
        case 404:
            throw IxApiClientError.NotFound(.task)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    /// Creates a new task
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`
    /// - `IxApiClientError.ProRequired`
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    func createTask(name: String, description: String?, dueDate: Date?, rrule: String?, reminders: [IxTaskReminder], subtasks: [IxSubTask], priority: Int?, itemId: String?) async throws -> IxTask {
        let url = URL(string: "\(Self.baseUrl)/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = TaskCreateOrEditReqBody(
            name: name,
            description: description,
            item_id: itemId,
            subtasks: subtasks.map({ NetworkSubTask(name: $0.name, completed: $0.completed)}),
            due_date: dueDate,
            rrule: rrule,
            priority: priority,
            reminders: reminders.map({ NetworkTaskReminder(days_before: $0.days_before, time_offset: $0.time_offset)})
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxTask(networkTask: try Self.decoder().decode(NetworkTask.self, from: data))
        case 400:
            throw IxApiClientError.InvalidData
        case 402:
            throw IxApiClientError.ProRequired(.unlimited_task_reminders)
        case 404:
            throw IxApiClientError.NotFound(.item)
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Edits an existing task
    ///
    /// ### Throws:
    /// - `IxApiClientError.InvalidData`
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    func editTask(taskId: String, name: String, description: String?, dueDate: Date?, rrule: String?, reminders: [IxTaskReminder], subtasks: [IxSubTask], priority: Int?, itemId: String?) async throws -> IxTask {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = TaskCreateOrEditReqBody(
            name: name,
            description: description,
            item_id: itemId,
            subtasks: subtasks.map({ NetworkSubTask(name: $0.name, completed: $0.completed)}),
            due_date: dueDate,
            rrule: rrule,
            priority: priority,
            reminders: reminders.map({ NetworkTaskReminder(days_before: $0.days_before, time_offset: $0.time_offset)})
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxTask(networkTask: try Self.decoder().decode(NetworkTask.self, from: data))
        case 400:
            throw IxApiClientError.InvalidData
        case 404:
            throw IxApiClientError.NotFound(.task)
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Sets the completion status of a task
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    func setTaskCompletion(taskId: String, completed: Bool) async throws -> IxTask {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)/completion")
            .appending(queryItems: [URLQueryItem(name: "completed", value: "\(completed)")])
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return IxTask(networkTask: try Self.decoder().decode(NetworkTask.self, from: data))
        case 404:
            throw IxApiClientError.NotFound(.task)
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Deletes a task via the [taskId]
    ///
    /// ### Throws:
    /// - `IxApiClientError.NotFound`
    /// - `IxApiClientError.Unknown`
    func deleteTask(taskId: String) async throws {
        let url = Self.baseUrl.appendingPathComponent("/tasks/\(taskId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 404:
            throw IxApiClientError.NotFound(.task)
        default:
            throw IxApiClientError.Unknown
        }
    }
    
    // MARK: - Suggestions
    
    /// Retrieves a list of default colors usable in lists.
    ///
    /// - Returns: A list of color strings.
    /// ### Throws:
    /// - `IxApiClientError.Unknown`
    func getColorsSuggestion() async throws -> [String] {
        let url = Self.baseUrl.appendingPathComponent("/suggestions/colors")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            let colorsSuggestion = try JSONDecoder().decode(NetworkColorsSuggestion.self, from: data)
            return colorsSuggestion.colors
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Retrieves a template for creating a new list.
    ///
    /// - Returns: A `NetworkListTemplateSuggestion` object.
    /// ### Throws:
    /// - `IxApiClientError.Unknown`
    func getListTemplateSuggestion() async throws -> NetworkListTemplateSuggestion {
        let url = Self.baseUrl.appendingPathComponent("/suggestions/templates/list")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(NetworkListTemplateSuggestion.self, from: data)
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Retrieves a template for creating a new category.
    ///
    /// - Returns: A `NetworkCategoryTemplateSuggestion` object.
    /// ### Throws:
    /// - `IxApiClientError.Unknown` unknown errors.
    func getCategoryTemplateSuggestion() async throws -> NetworkCategoryTemplateSuggestion {
        let url = Self.baseUrl.appendingPathComponent("/suggestions/templates/category")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(NetworkCategoryTemplateSuggestion.self, from: data)
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Retrieves a template for creating a new item.
    ///
    /// - Returns: A `NetworkItemTemplateSuggestion` object.
    /// ### Throws:
    /// - `IxApiClientError.Unknown` for authentication or unknown errors.
    func getItemTemplateSuggestion() async throws -> NetworkItemTemplateSuggestion {
        let url = Self.baseUrl.appendingPathComponent("/suggestions/templates/item")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(NetworkItemTemplateSuggestion.self, from: data)
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            throw IxApiClientError.Unknown
        }
    }

    /// Retrieves a template for creating a new task.
    ///
    /// - Returns: A `NetworkTaskTemplateSuggestion` object.
    /// ### Throws:
    /// - `IxApiClientError.Unknown`
    func getTaskTemplateSuggestion() async throws -> NetworkTaskTemplateSuggestion {
        let url = Self.baseUrl.appendingPathComponent("/suggestions/templates/task")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(NetworkTaskTemplateSuggestion.self, from: data)
        case 401:
            await setAuthenticationStatus(authenticationStatus: .Unauthenticated)
            throw IxApiClientError.Unauthenticated
        default:
            throw IxApiClientError.Unknown
        }
    }
}
