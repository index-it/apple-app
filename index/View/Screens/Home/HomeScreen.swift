//
//  HomeScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import IxCoreKit
import SwiftUI

struct HomeScreen: View {
    @Environment(IxNavigator.self) var navigator
    @Environment(CalendarManager.self) var calendarManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var siriManager: SiriManager
    
    @AppStorage(AppStorageKeys.onboardingShowed) private var onboardingShowed: Bool = false
    @AppStorage(AppStorageKeys.Tasks.showCalendarEvents) private var showCalendarEvents = AppStorageKeys.Defaults.showCalendarEvents
    @AppStorage(AppStorageKeys.Tasks.enabledCalendars) private var enabledCalendarIds = AppStorageKeys.Defaults.enabledCalendars

    func onOnboardingEnded() {
        onboardingShowed = true

        Task {
            _ = await notificationManager.requestPermissions()
            siriManager.requestPermissions()
            
            // TODO: Move to onboarding button
            if !calendarManager.permitted {
                let calendarPermitted = await calendarManager.requestPermissions()
                if calendarPermitted {
                    showCalendarEvents = true
                    enabledCalendarIds = calendarManager.store.calendars(for: .event).map(\.calendarIdentifier)
                }
            }
        }
    }

    var body: some View {
        @Bindable var navigator = navigator

        TabView(selection: $navigator.tab) {
            Tab("Your tasks", systemImage: "rectangle.grid.1x2.fill", value: IxTab.tasks) {
                TasksTabView()
            }

            Tab("Your lists", systemImage: "square.grid.2x2.fill", value: IxTab.lists) {
                NavigationView {
                    ListsGridScreen(archived: false)
                }
            }
        }
        .onChange(of: navigator.tab, initial: false) { _, newValue in
            Task {
                await IxSystemIntegration.donateIntent(newValue == .lists ? IxDonatableIntent.openLists : IxDonatableIntent.openTasks)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    !onboardingShowed
                },
                set: { _ in
                    onOnboardingEnded()
                }
            )
        ) {
            OnboardingView {
                onOnboardingEnded()
            }
        }
    }
}

#Preview {
    NavigationView {
        HomeScreen()
    }
}
