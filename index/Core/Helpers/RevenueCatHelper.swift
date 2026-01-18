//
//  RevenueCatHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import Foundation
import IxCoreKit
import os
import RevenueCat

private let log = Logger(subsystem: IxSubsystems.APP, category: "RevenueCatHelper")

public enum RevenueCatHelper {
    private static let apiKey = "appl_nPoYUABJDUWtNxeVeGCrIxTnPJA"

    /// Call this once at application startup to configure RevenueCat
    public static func configure() {
        #if DEBUG
            Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: RevenueCatHelper.apiKey)
    }

    public static func login(userId: String) async {
        do {
            _ = try await Purchases.shared.logIn(userId)
        } catch {
            log.error("Failed logging in user in revenue cat: \(error)")
        }
    }

    public static func logout() async {
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            log.error("Failed logging out user from revenue cat: \(error)")
        }
    }
}
