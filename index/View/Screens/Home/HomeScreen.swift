//
//  HomeScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import SwiftUI
import IxCoreKit

struct HomeScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
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
            
            Tab("Settings", systemImage: "gearshape.fill", value: HomeTab.settings) {
                SettingsTabView()
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    !onboardingShowed
                },
                set: { newValue in
                    onboardingShowed = true
                    
                    Task {
                        await NotificationManager.shared.request()
                    }
                }
            )
        ) {
            OnboardingView {
                onboardingShowed = true
                
                Task {
                    await NotificationManager.shared.request()
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
