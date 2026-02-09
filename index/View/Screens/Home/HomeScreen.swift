//
//  HomeScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import IxCoreKit
import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var siriManager: SiriManager
    @AppStorage(AppStorageKeys.onboardingShowed) private var onboardingShowed: Bool = false

    var body: some View {
        TabView(selection: $navigationManager.selectedHomeTab) {
            Tab("Your tasks", systemImage: "rectangle.grid.1x2.fill", value: HomeTab.tasks) {
                TasksTabView()
            }

            Tab("Your lists", systemImage: "square.grid.2x2.fill", value: HomeTab.lists) {
                NavigationView {
                    ListsGridScreen(archived: false)
                }
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    !onboardingShowed
                },
                set: { _ in
                    onboardingShowed = true

                    Task {
                        let _ = await notificationManager.requestPermissions()
                        siriManager.requestPermissions()
                    }
                }
            )
        ) {
            OnboardingView {
                onboardingShowed = true

                Task {
                    let _ = await notificationManager.requestPermissions()
                    siriManager.requestPermissions()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        HomeScreen()
    }
}
