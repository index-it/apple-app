//
//  AccountTab.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    
    
    var body: some View {
        Button {
            Task {
                do {
                    try await ixApiClient.logout()
                } catch {
                    errorService.insert(.customMessage())
                }
            }
        } label: {
            Text("Logout")
        }
    }
}

#Preview {
    SettingsTabView()
}
