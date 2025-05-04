//
//  RevenueCatHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import RevenueCat
import os
import Foundation

fileprivate let log = Logger(subsystem: IxIdentifiers.IX_CORE_KIT_IDENTIFIER, category: "RevenueCatHelper")

public struct RevenueCatHelper {
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
