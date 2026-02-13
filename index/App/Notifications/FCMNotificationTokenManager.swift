//
//  IxNotificationTokenHandler.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 13/02/26.
//

import OSLog

private let log = Logger.appLogger

import IxCoreKit

actor FCMNotificationTokenManager {
    static let shared = FCMNotificationTokenManager()
    
    var ixApiClient: IxApiClient? = nil
    var fcmToken: String? = nil
    var authenticated = false
    var sent = false
    
    private init() {}
    
    func setup(ixApiClient: IxApiClient) {
        self.ixApiClient = ixApiClient
    }

    func setFcmToken(_ fcmToken: String) async {
        self.fcmToken = fcmToken
        await tryToSendTokenToBackend()
    }
    
    func setAuthenticated(_ authenticated: Bool) async {
        self.authenticated = authenticated
        await tryToSendTokenToBackend()
    }
    
    func clearTokenAndAuthStatus() {
        self.fcmToken = nil
        self.authenticated = false
    }
    
    func tryToSendTokenToBackend() async {
        if sent {
            log.info("Skipped sending FCM token to backend server, because it was already sent")
            return
        }
        
        guard let ixApiClient else {
            log.info("Cannot send FCM token to backend server, because ixApiClient is nil")
            return
        }
        
        if let fcmToken, authenticated {
            do {
                try await ixApiClient.sendNotificationRegistrationToken(token: fcmToken)
                log.info("Sent firebase messagin token to server")
            } catch {
                log.error("Failed sending firebase messaging token to server: \(error)")
            }
        }
    }
}
