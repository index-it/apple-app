//
//  ScrollTest.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//

import SwiftUI

struct CenteredScrollView: View {
    private var items = Array(1...40)
    @State private var selectedItem: Int? = 1
    
    var body: some View {
        VStack {
            Spacer()
            
            GeometryReader { proxy in
                ScrollViewReader { scroller in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(items, id: \.hashValue) { item in
                                Text("\(item)")
                                    .fontWeight(item == selectedItem ? .bold : .regular)
                                    .font(item == selectedItem ? .title : .caption)
                                    .id(item)
                            }
                        }.scrollTargetLayout()
//                            .onChange(of: selectedItem) { newValue in
//                                withAnimation {
//                                    scroller.scrollTo(newValue, anchor: .center)
//                                }
//                            }
                    }.scrollPosition(id: $selectedItem, anchor: .center)
                        .scrollTargetBehavior(.viewAligned)
                        .safeAreaPadding(.horizontal, proxy.size.width / 2)
                        .onScrollPhaseChange { oldPhase, newPhase in
                            if !newPhase.isScrolling {
                                withAnimation {
                                    scroller.scrollTo(selectedItem, anchor: .center)
                                }
                            }
                        }
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    CenteredScrollView()
}
