//
//  AppDelegate.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/03/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import RevenueCat
import IxCoreKit

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    private let ixApiClient = IxApiClient { _ in }
    
    // Application initialization
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_nPoYUABJDUWtNxeVeGCrIxTnPJA")
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Since we use SwiftUI we need to manually update the apns token for Firebase messaging
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Handle app opening from a notification when the app is not in foreground
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let _ = userInfo["task-id"] as? String {
            handleTaskNotification()
        }
        
        // Notify Firebase about the received notification for analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }
    
    // Send new firebase token to Index backend
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        Task {
            do {
                _ = try await self.ixApiClient.sendNotificationRegistrationToken(token: token)
            } catch {
                print("Failed sending firebase messaging token to the server: \(error)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when the app is in foreground, this doesn't handle the user tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        return [[.sound, .badge, .banner]]
    }
    
    // Handle user tap on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        if let _ = userInfo["task-id"] as? String {
            handleTaskNotification()
        }
    }
    
    private func handleTaskNotification() {
        NotificationCenter.default.post(
            name: .navigateToTasks,
            object: nil,
            userInfo: [:]
        )
    }
}

extension Notification.Name {
    static let navigateToTasks = Notification.Name("navigateToTasks")
}
