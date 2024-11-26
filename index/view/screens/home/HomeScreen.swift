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
            Tab("Tasks", systemImage: "rectangle.grid.1x2.fill", value: 0) {
                TasksTabView()
            }
            
            Tab("Lists", systemImage: "square.grid.2x2.fill", value: 1) {
                ListsTabView()
            }
            
            Tab("Account", systemImage: "gearshape.fill", value: 2) {
                AccountTabView()
            }
        }.navigationTitle(selectedTab == 0 ? "Tasks" : (selectedTab == 1 ? "Lists" : "Settings"))
            
    }
}

#Preview {
    NavigationView {
        HomeScreen()
    }
}
