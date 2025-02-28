//
//  OnboardingView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/02/25.
//

import SwiftUI

struct OnboardingPage {
    let title: String
    let description: String
    let image: String
}

struct OnboardingView: View {
    static private var pages: [OnboardingPage] = [
        .init(title: "Create the lists you need", description: "You can create as many lists as you need. Each list has a name, color and emoji.\nYou can also share a list or make it public!", image: ""),
        .init(title: "Move through categories", description: "You can (optionally) use categories to organize your list items. Easily change an item category by swiping it!", image: ""),
        .init(title: "Complete list items", description: "Tap on an item to discover the available actions.\nYou can complete / un-complete items, and make sure to checkout the top right dropdown menu for some handy options!", image: ""),
        .init(title: "Create tasks to stay organized", description: "Once created, you can then long press the task to view some options, swipe it left to complete it, or right to delete it!", image: ""),
        .init(title: "Enjoy the app!", description: "Hey, my name is Giulio. I'm a passionate spaghetti coder from Italy and currently it's just me developing this app :>\n\nIf you like the idea of the app and wanna support the development, feel free to purchase the pro version!\n\nThank you for reading this ❤️\nEnjoy using Index!", image: "")
    ]
    
    var onClose: () -> ()
    
    @State private var selectedPage = 0

    
    var body: some View {
        NavigationView {
            VStack {
                PagingScrollView
                
                Button {
                    if selectedPage < Self.pages.count - 1 {
                        withAnimation {
                            selectedPage += 1
                        }
                    } else {
                        onClose()
                    }
                } label: {
                    Text(selectedPage == Self.pages.count - 1 ? "Done" : "Continue")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
            }.toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                            
                    }
                }
            }
        }.onAppear {
            selectedPage = 0
            
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.secondaryLabel
        }
    }
    
    var PagingScrollView: some View {
        TabView(selection: $selectedPage) {
            ForEach(Array(Self.pages.enumerated()), id: \.offset) { index, page in
                VStack {
                    Text(page.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(page.description)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.vertical)
                }.padding()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}

#Preview {
    OnboardingView() { }
}
