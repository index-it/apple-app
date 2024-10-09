//
//  HomeScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var ixApiClient: IxApiClient
    
    var body: some View {
        Button("Logout") {
            Task {
                try await ixApiClient.logout()
            }
        }
    }
}

#Preview {
    HomeScreen()
}
