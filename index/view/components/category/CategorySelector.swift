//
//  CategorySelector.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import SwiftUI

struct CategorySelector: View {
    var categories: [IxListCategory]
    @Binding var selectedCategoryId: String?
    
    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollReader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 24) {
                        NoCategoryIndicator(selected: selectedCategoryId == "none")
                            .id("none")
                        
                        ForEach(categories) { category in
                            CategoryIndicator(category: category, selected: category.id == selectedCategoryId)
                                .id(category.id)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(
                                            x: phase.isIdentity ? 3 : 1,
                                            y: phase.isIdentity ? 3 : 1
                                        )
                                }
                        }
                        
                        NewCategoryIndicator(selected: selectedCategoryId == "new")
                            .id("new")
                    }
                    .scrollTargetLayout()
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: CategoryUIDefaults.height + 48)

                }.scrollPosition(id: $selectedCategoryId, anchor: .center)
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(geoProxy.size.width / 2)
                    .onScrollPhaseChange { oldPhase, newPhase in
                        if !newPhase.isScrolling {
                            withAnimation(.snappy(duration: 0.1)) {
                                scrollReader.scrollTo(selectedCategoryId, anchor: .center)
                            }
                        }
                    }
                    .frame(height: CategoryUIDefaults.height + 48)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedCategoryId: String? = nil
    var categories = [IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), ]
    
    CategorySelector(categories: categories, selectedCategoryId: $selectedCategoryId)
        .onAppear {
            selectedCategoryId = categories.first?.id
        }
}
