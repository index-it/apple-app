//
//  OnboardingView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/02/25.
//

import IxCoreKit
import SwiftUI

struct OnboardingPage {
    let title: String
    let description: String
    let id: OnboardingPageId

    enum OnboardingPageId {
        case lists
        case items
        case tasks
        case integrations
        case thanks
    }
}

struct OnboardingView: View {
    private static var pages: [OnboardingPage] = [
        .init(title: "Drop your thoughts in Lists", description: "You can create as many lists as you need to organize your thoughts.\nYou can also share them with your friends and family or make them public!", id: .lists),
        .init(title: "Completion, links and notes", description: "When inside a list, swipe on a list item to complete it, you can also assign it a link or add some notes!", id: .items),
        .init(title: "Use tasks to stay organized", description: "Create tasks with priorities, reminders, recurrence and more options to organize your day, then swipe to complete or delete them!", id: .tasks),
        .init(title: "Seamlessly integrated", description: "Add anything to a list simply by hitting the share button from any app, drop a widget on your home or add quick buttons to your control center and lock screen!", id: .integrations),
        .init(title: "Enjoy the app!", description: "Hey, my name is Giulio. I'm a spaghetti coder from Italy and currently it's just me developing this app :>\n\nIf you like the idea of the app and wanna support the development, feel free to share it with your friends!\n\nThank you for reading this ❤️\nEnjoy using Index!", id: .thanks),
    ]
    private static var lists: [IxList] = [
        IxList.mock(name: "Travel ideas", emoji: "🌋", color: "#000000"),
        IxList.mock(name: "Ideas", emoji: "💡", color: "#167E54"),
        IxList.mock(name: "Goals", emoji: "🧭", color: "#B4211C"),
        IxList.mock(name: "Sailing", emoji: "⛵", color: "#0249BD"),
    ]

    private let itemsImages = [
        "checkmark.circle",
        "link",
        "note.text",
    ]

    private let tasksImages = [
        "flag",
        "bell",
        "repeat",
    ]

    var onClose: () -> Void

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
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
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
            ForEach(Array(Self.pages.enumerated()), id: \.offset) {
                index,
                    page in
                VStack {
                    Text(page.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(page.description)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.bottom, page.id == .thanks ? -16 : 4)
                        .padding(.horizontal)

                    if page.id == .lists {
                        listsDemo
                            .padding()
                            .padding(.top, 24)
                    } else if page.id == .items {
                        itemsDemo
                    } else if page.id == .tasks {
                        tasksDemo
                    } else if page.id == .integrations {
                        Image("ios_system_illustration")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.top, 32)
                            .padding(.horizontal)
                    } else {
                        Image("giulio")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(Circle())
                            .scaleEffect(0.75)
                    }
                }.padding()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }

    private var listsDemo: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
            ForEach(Self.lists) { list in
                ListCard(
                    list: list,
                    owner: false,
                    onTap: {},
                    onShare: {},
                    onEdit: {},
                    onArchiveToggle: {},
                    onDelete: {},
                    onLeave: {},
                    withInteractions: false
                )
            }
        }
    }

    private var itemsDemo: some View {
        ZStack {
            if itemsImages.count > 0 {
                ImageOnCircle(imageName: itemsImages[0], angle: 0)
            }

            if itemsImages.count > 1 {
                ImageOnCircle(imageName: itemsImages[1], angle: 120)
            }

            if itemsImages.count > 2 {
                ImageOnCircle(imageName: itemsImages[2], angle: 240)
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
    }

    private var tasksDemo: some View {
        ZStack {
            if tasksImages.count > 0 {
                ImageOnCircle(imageName: tasksImages[0], angle: 0)
            }

            if tasksImages.count > 1 {
                ImageOnCircle(imageName: tasksImages[1], angle: 120)
            }

            if tasksImages.count > 2 {
                ImageOnCircle(imageName: tasksImages[2], angle: 240)
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
    }
}

struct ImageOnCircle: View {
    let imageName: String
    let angle: Double

    var body: some View {
        // Calculate the position on the circle
        // We'll put the image at 80% of the radius from the center
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(center.x, center.y) * 0.5

            // Convert angle to radians and calculate position
            let radians = angle * .pi / 180
            let xPosition = center.x + radius * cos(radians)
            let yPosition = center.y + radius * sin(radians)

            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.2)
                .position(x: xPosition, y: yPosition)
        }
    }
}

#Preview {
    OnboardingView {}
}
