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
    static let shared = NotificationManager()
    
    private var permitted = false
    
    private init() {
        Task {
            await checkForPermissions()
        }
    }
    
    func request() async -> Bool {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            let appDelegate = UIApplication.shared
            appDelegate.registerForRemoteNotifications()
            
            permitted = true
            return true
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
    
    func hasPermissions() -> Bool {
        return permitted
    }
    
    func setupNotificationCategories() {
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([taskCategory])
    }
}
