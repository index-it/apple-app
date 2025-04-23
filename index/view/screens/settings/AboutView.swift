//
//  AboutView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/03/25.
//

import SwiftUI
import StoreKit

struct AboutView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.requestReview) var requestReview
    
    @State private var showPaywall = false
    
    @AppStorage(AppStorageKeys.logged_in_user) private var user: User?
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    Image(uiImage: UIApplication.shared.alternateIconName == nil
                          ? UIImage(named: "AppIcon60x60") ?? UIImage()
                          : UIImage(named: UIApplication.shared.alternateIconName!) ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .padding(.bottom, 8)
                    .padding(.top, 48)
                    
                    Text("Ciao!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    
                    Text("I created this app to be more organized and intentional in my everyday life.")
                        .multilineTextAlignment(.leading)
                    
                    Text("I'd love to hear your feedback. I can't promise that I'll implement every change, but I'll listen and do what I can.")
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                    
                    
                    Text("How can I support Index development?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                    Text("You can buy the Pro version or share the app with the people in your life, and give feedback. A nice review on the App Store doesn't hurt, either :)")
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                    
                    Button {
                        requestReview()
                    } label: {
                        Label("Review App", systemImage: "heart")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(AboutButtonStyle())
                    
                    ShareLink(item: URL(string: "https://index-it.app")!) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemGray5))
                            )
                            .foregroundColor(Color.primary.opacity(0.7))
                    }.padding(.top, 4)
                    
                    
                    if user?.has_pro != true {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Get Pro", systemImage: "crown")
                                .frame(maxWidth: .infinity)
                        }.buttonStyle(AboutButtonStyle())
                            .padding(.top, 4)
                    }
                    
                    
                    
                    
                    Text("How can I share feedback?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                    Text("I will definitely read all the feedback and try to improve the app!")
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                    
                    Button {
                        let email = "support@index-it.app"
                        let subject = "iOS Feedback"
                        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let mailtoURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)")!
                       
                        if UIApplication.shared.canOpenURL(mailtoURL) {
                            UIApplication.shared.open(mailtoURL)
                        }
                    } label: {
                        Label("Send me an email", systemImage: "paperplane")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(AboutButtonStyle())
                        .padding(.top, 4)
                    
                    Button {
                        UIPasteboard.general.string = "support@index-it.app"
                    } label: {
                        Label("Copy email address", systemImage: "document.on.document")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(AboutButtonStyle())
                        .padding(.top, 4)
                    
                    Text("Who are you?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                    Text("Hey! I'm a computer science student from Italy with a passion for sports. You can find more about me at my website ^^")
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                    
                    Button {
                        openURL(URL(string: "https://giuliopime.dev")!)
                    } label: {
                        Text("giuliopime.dev")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(AboutButtonStyle())
                        .padding(.top, 4)
                        .padding(.bottom, 48)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .padding(.horizontal, 32)
            .paywallCover(isPresented: $showPaywall)
        }
        .toolbarBackground(UIColor.systemGray6.toColor(), for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: URL(string: "https://index-it.app")!)
            }
        }
    }
}

#Preview {
    AboutView()
}
