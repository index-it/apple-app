//
//  SplashScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/10/24.
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        HStack {
            ProgressView()
            Text("authenticating...")
        }
    }
}

#Preview {
    SplashScreen()
}
