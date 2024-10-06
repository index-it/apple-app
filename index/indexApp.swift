//
//  indexApp.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/09/24.
//

import SwiftUI
import SwiftData

@main
struct indexApp: App {
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var ixApiClient = IxApiClient()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(navigationManager)
                .environmentObject(ixApiClient)
        }
    }
}
