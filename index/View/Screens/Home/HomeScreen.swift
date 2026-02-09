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
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var siriManager: SiriManager
    @AppStorage(AppStorageKeys.onboardingShowed) private var onboardingShowed: Bool = false
    
    func onOnboardingEnded() {
        onboardingShowed = true
        
        Task {
            let _ = await notificationManager.requestPermissions()
            siriManager.requestPermissions()
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
