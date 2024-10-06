//
//  SocialLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI

struct SocialLoginScreen: View {
    private func loginWithGoogle() {
        
    }
    
    private func loginWithApple() {
        
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("welcome to Index")
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("be intentional.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
            }
            
            Button(action: loginWithGoogle) {
                Label("Continue with Google", systemImage: "touchid")
            }
            
            Button(action: loginWithApple) {
                Label("Continue with Apple", systemImage: "touchid")
            }
            
            NavigationLink(value: NavigationRoute.EmailLogin) {
                Text("Use your email")
            }
            
        }.frame(maxHeight: .infinity, alignment: .bottom).padding()
    }
}

#Preview {
    SocialLoginScreen()
}
