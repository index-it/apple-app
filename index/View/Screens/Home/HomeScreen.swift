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
                        await notificationManager.requestPermissions()
                    }
                }
            )
        ) {
            OnboardingView {
                onboardingShowed = true

                Task {
                    await notificationManager.requestPermissions()
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
