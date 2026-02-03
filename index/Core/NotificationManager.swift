//
//  NotificationManager.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/04/25.
//

import Foundation
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    private(set) var permitted = false

    func requestPermissions() async -> Bool {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

        do {
            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            if authorized {
                UIApplication.shared.registerForRemoteNotifications()
                
                permitted = true
                return true
            } else {
                permitted = false
                return false
            }
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            permitted = false
            return false
        }
    }

    func checkForPermissions() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        
        switch status.authorizationStatus {
        case .authorized:
            permitted = true
        default:
            permitted = false
        }
    }
}
