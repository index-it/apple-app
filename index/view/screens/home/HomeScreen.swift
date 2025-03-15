//
//  HomeScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        TabView(selection: $navigationManager.selectedHomeTab) {
            Tab("Your tasks", systemImage: "rectangle.grid.1x2.fill", value: HomeTab.tasks) {
                TasksTabView()
            }
            
            Tab("Your lists", systemImage: "square.grid.2x2.fill", value: HomeTab.lists) {
                ListsTabView()
            }
            
            Tab("Settings", systemImage: "gearshape.fill", value: HomeTab.settings) {
                SettingsTabView()
            }
        }
    }
}

#Preview {
    NavigationView {
        HomeScreen()
    }
}
