//
//  IxAppDelegate.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/03/25.
//

import FirebaseCore
import FirebaseMessaging
import IxCoreKit
import os
import RevenueCat
import SwiftData
import SwiftUI

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "IxAppDelegate")

/// Responsible for initializing third party services
class IxAppDelegate: NSObject, UIApplicationDelegate {
    private let ixApiClient = IxApiClient(authChangeCallback: { _ in })

    // Application initialization
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        RevenueCatHelper.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        setupNotificationCategoriesAndActions()

        return true
    }
}

extension IxAppDelegate: MessagingDelegate {
    // Since we use SwiftUI we need to manually update the apns token for Firebase messaging
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Send new firebase token to Index backend
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        Task {
            do {
                _ = try await self.ixApiClient.sendNotificationRegistrationToken(token: token)
                log.debug("Sent firebase messaging token to the server: \(token)")
            } catch {
                log.error("Failed sending firebase messaging token to the server: \(error)")
            }
        }
    }
}

extension IxAppDelegate: UNUserNotificationCenterDelegate {
    private func getTask(taskId: String) async throws -> IxTask {
        var taskFetchDescriptor = FetchDescriptor<IxTask>(
            predicate: #Predicate { task in
                task.id == taskId
            }
        )
        taskFetchDescriptor.fetchLimit = 1

        if let localTask = try ModelContainerProvider.shared.mainContext.fetch(taskFetchDescriptor).first {
            return localTask
        }

        return try await ixApiClient.getTask(taskId: taskId)
    }

    // called when user taps on notification or one of its actions
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        log.debug("Received notification")
        let userInfo = response.notification.request.content.userInfo

        if response.notification.request.content.categoryIdentifier == IxNotificationIdentifiers.taskReminderCategory,
           let taskId = userInfo["task-id"] as? String
        {
            let modelContainer = ModelContainerProvider.shared
            var taskFetchDescriptor = FetchDescriptor<IxTask>(
                predicate: #Predicate { task in
                    task.id == taskId
                }
            )
            taskFetchDescriptor.fetchLimit = 1
            
            switch response.actionIdentifier {
            case IxNotificationIdentifiers.taskCompleteAction:
                Task {
                    do {
                        let updatedTask = try await self.ixApiClient.setTaskCompletion(taskId: taskId, completed: true)
                        try modelContainer.mainContext.transaction {
                            modelContainer.mainContext.insert(updatedTask)
                        }
                    } catch {
                        log.error("Failed updating task: \(error)")
                    }
                }
            case IxNotificationIdentifiers.taskRemindInAnHourAction:
                Task {
                    do {
                        let task = try await getTask(taskId: taskId)
                        guard let dueDate = task.dueDate else { return }

                        let utcCalendar = DateHelper.calendar()
                        let newReminderTimeOffsetDate = utcCalendar.date(byAdding: .hour, value: 1, to: Date.now)!
                        let newReminderTimeOffset = Int64(newReminderTimeOffsetDate.timeIntervalSince(utcCalendar.startOfDay(for: newReminderTimeOffsetDate))) * 1000
                        var newReminderDaysBefore = DateHelper.daysDifference(newReminderTimeOffsetDate, dueDate)
                        if newReminderDaysBefore == -1 {
                            task.dueDate = newReminderTimeOffsetDate
                            newReminderDaysBefore = 0
                        } else if newReminderDaysBefore < -1 {
                            // this should never happen
                            return
                        }

                        task.reminders.append(IxTaskReminder(daysBefore: Int64(newReminderDaysBefore), timeOffset: newReminderTimeOffset))

                        let updatedTask = try await self.ixApiClient.editTask(
                            taskId: taskId,
                            name: task.name,
                            description: task.taskDescription,
                            dueDate: task.dueDate,
                            rrule: task.rrule,
                            reminders: task.reminders,
                            subtasks: task.subtasks,
                            priority: task.priority,
                            itemId: task.itemId
                        )

                        try modelContainer.mainContext.transaction {
                            modelContainer.mainContext.insert(updatedTask)
                        }
                    } catch {
                        log.error("Failed updating task: \(error)")
                    }
                }
            case IxNotificationIdentifiers.taskRemindTomorrowAction:
                Task {
                    do {
                        let task = try await getTask(taskId: taskId)
                        guard let dueDate = task.dueDate else { return }

                        let tomorrow = DateHelper.calendar().date(byAdding: .day, value: 1, to: Date.now)!
                        var newReminderDaysBefore = DateHelper.daysDifference(tomorrow, dueDate)
                        if newReminderDaysBefore == -1 {
                            // this means we exceeded the due date of the task with the new reminder
                            // let's change the due date of the task to allow a reminder to be set
                            // since reminders can only be set x (with x up to 0) days before, not in the future
                            task.dueDate = tomorrow
                            newReminderDaysBefore = 0
                        } else if newReminderDaysBefore < -1 {
                            // this should never happen
                            return
                        }
                        let newReminderTimeOffset = DateHelper.startOfDayOffsetFromLocalToUtc(offset: 8 * 60 * 60 * 1000)

                        task.reminders.append(IxTaskReminder(daysBefore: Int64(newReminderDaysBefore), timeOffset: newReminderTimeOffset))

                        let updatedTask = try await self.ixApiClient.editTask(
                            taskId: taskId,
                            name: task.name,
                            description: task.taskDescription,
                            dueDate: task.dueDate,
                            rrule: task.rrule,
                            reminders: task.reminders,
                            subtasks: task.subtasks,
                            priority: task.priority,
                            itemId: task.itemId
                        )

                        try modelContainer.mainContext.transaction {
                            modelContainer.mainContext.insert(updatedTask)
                        }
                    } catch {
                        log.error("Failed updating task: \(error)")
                    }
                }
            case UNNotificationDefaultActionIdentifier:
                NotificationCenter.default.post(
                    name: .navigateToTasks,
                    object: nil,
                    userInfo: [:]
                )
            default:
                break;
            }
        } else {
            // do nothing
        }

        completionHandler()
    }

    // decide what to show when a notification is received and app is in FOREGROUND
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.sound, .badge, .banner])
    }
}

extension IxAppDelegate {
    private func setupNotificationCategoriesAndActions() {
        let completeTaskAction = UNNotificationAction(
            identifier: IxNotificationIdentifiers.taskCompleteAction,
            title: "Mark as completed",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle.fill")
        )
        let remindInAnHourTaskAction = UNNotificationAction(
            identifier: IxNotificationIdentifiers.taskRemindInAnHourAction,
            title: "Remind me in an hour",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "clock")
        )
        let remindTomorrowTaskAction = UNNotificationAction(
            identifier: IxNotificationIdentifiers.taskRemindTomorrowAction,
            title: "Remind me tomorrow",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "calendar")
        )

        let taskReminderCategory = UNNotificationCategory(
            identifier: IxNotificationIdentifiers.taskReminderCategory,
            actions: [completeTaskAction, remindInAnHourTaskAction, remindTomorrowTaskAction],
            intentIdentifiers: [], // TODO: to integrate with intents
            hiddenPreviewsBodyPlaceholder: "Task reminder",
            options: .allowInCarPlay
        )

        UNUserNotificationCenter.current().setNotificationCategories([taskReminderCategory])
    }
}

extension Notification.Name {
    static let navigateToTasks = Notification.Name("navigateToTasks")
}
