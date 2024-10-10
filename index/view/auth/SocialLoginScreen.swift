//
//  SocialLoginScreen.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 05/10/24.
//

import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignInSwift
import GoogleSignIn

struct SocialLoginScreen: View {
    @Environment(\.colorScheme) var currentScheme
    
    func loginWithGoogle() {
        // TODO: https://paulallies.medium.com/google-sign-in-swiftui-2909e01ea4ed
    }
    
    private func loginWithApple() {
        // TODO: https://www.kodeco.com/4875322-sign-in-with-apple-using-swiftui
    }
    
    var body: some View {
        ZStack {
            if #available(macOS 15.0, *) {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                    ],
                    colors: currentScheme == .light ? [
                        Color(red: 237/255, green: 255/255, blue: 242/255), // Light mint green
                        Color(red: 185/255, green: 250/255, blue: 194/255), // Pale green
                        Color(red: 235/255, green: 252/255, blue: 237/255), // Soft green
                        Color(red: 210/255, green: 245/255, blue: 200/255), // Additional soft green
                        Color(red: 240/255, green: 245/255, blue: 240/255), // Soft grey-green for extra blending
                        Color(red: 200/255, green: 240/255, blue: 210/255), // Extra green tone for variety
                        Color(red: 220/255, green: 250/255, blue: 230/255), // Light blending tone
                        Color(red: 215/255, green: 255/255, blue: 235/255), // Soft minty finish
                        Color(red: 195/255, green: 235/255, blue: 210/255)  // Deep soft green
                    ] : [
                        Color(red: 10/255, green: 30/255, blue: 20/255),  // Darker mint green
                        Color(red: 5/255, green: 50/255, blue: 25/255),   // Dark green
                        Color(red: 15/255, green: 60/255, blue: 30/255),  // Deep forest green
                        Color(red: 20/255, green: 55/255, blue: 45/255),  // Muted dark green
                        Color(red: 10/255, green: 25/255, blue: 15/255),  // Dark olive green
                        Color(red: 15/255, green: 40/255, blue: 25/255),  // Deep moss green
                        Color(red: 20/255, green: 50/255, blue: 35/255),  // Dark teal
                        Color(red: 25/255, green: 65/255, blue: 45/255),  // Muted dark teal
                        Color(red: 5/255, green: 20/255, blue: 15/255)    // Very dark green
                    ]
                ).ignoresSafeArea()
            } else {
                // Fallback on earlier versions
            }
            
            VStack {
                Text("be intentional.")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            
            VStack {
                Spacer()
                
                VStack {
                    Button {
                        loginWithApple()
                    } label: {
                        Label("Continue with Apple", systemImage: "apple.logo")
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        loginWithGoogle()
                    } label: {
                        Label("Continue with Google", image: ImageResource(name: "google_logo", bundle: Bundle.main))
                            .frame(maxWidth: .infinity)
                    }
                    
                    
                    Button {} label: {
                        Label {
                            Text("Continue with email")
                        } icon: {
                            Image(systemName: "envelope")
                                .fontWeight(.regular)
                        }.frame(maxWidth: .infinity)
                    }
                    
                }.foregroundStyle(.primary)
                    .fontWeight(.semibold)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding()
                
                
                Text("By continuing you agree to our \(Text("[Terms of Service](https://index-it.app/terms)").fontWeight(.semibold)) and \(Text("[Privacy Policy](https://index-it.app/privacy)").fontWeight(.semibold))")
                    .tint(.primary)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

//        VStack(spacing: 20) {
//            VStack {
//                Text("welcome to Index")
//                    .font(.title)
//                    .fontWeight(.semibold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                
//                Text("be intentional.")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .foregroundStyle(.gray)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.bottom)
//            }
//            
//            Button(action: loginWithGoogle) {
//                Label("Continue with Google", systemImage: "touchid")
//            }
//            
//            Button(action: loginWithApple) {
//                Label("Continue with Apple", systemImage: "touchid")
//            }
//            
//            NavigationLink(value: NavigationRoute.EmailLogin) {
//                Text("Use your email")
//            }
//            
//        }.frame(maxHeight: .infinity, alignment: .bottom).padding()
    }
}

#Preview {
    SocialLoginScreen()
}
