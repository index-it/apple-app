//
//  HomeScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var ixApiClient: IxApiClient
    
    @State private var selectedTab = 1
    @State private var search: String = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Your tasks", systemImage: "rectangle.grid.1x2.fill", value: 0) {
                TasksTabView()
            }
            
            Tab("Your lists", systemImage: "square.grid.2x2.fill", value: 1) {
                ListsTabView()
            }
            
            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
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
