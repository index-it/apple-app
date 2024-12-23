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
    
    var onSelectedTap: (_ categoryId: String?) -> ()
    var onNewCategoryTap: () -> ()
    
    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollReader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 24) {
                        NoCategoryIndicator(selected: selectedCategoryId == "none")
                            .id("none")
                            .scrollTransition(axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(
                                        x: phase.isIdentity ? 1.75 : 1,
                                        y: phase.isIdentity ? 1.75 : 1
                                    )
                            }
                            .onTapGesture {
                                if selectedCategoryId == "none" {
                                    onSelectedTap(nil)
                                } else {
                                    withAnimation {
                                        selectedCategoryId = "none"
                                    }
                                }
                            }
                        
                        ForEach(categories) { category in
                            CategoryIndicator(category: category, selected: category.id == selectedCategoryId)
                                .id(category.id)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(
                                            x: phase.isIdentity ? 1.75 : 1,
                                            y: phase.isIdentity ? 1.75 : 1
                                        )
                                }
                                .onTapGesture {
                                    if category.id == selectedCategoryId {
                                        onSelectedTap(category.id)
                                    } else {
                                        withAnimation {
                                            selectedCategoryId = category.id
                                        }
                                    }
                                }
                        }
                        
                        NewCategoryIndicator(selected: selectedCategoryId == "new")
                            .id("new")
                            .scrollTransition(axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(
                                        x: phase.isIdentity ? 1.75 : 1,
                                        y: phase.isIdentity ? 1.75 : 1
                                    )
                            }
                            .onTapGesture {
                                if selectedCategoryId == "new" {
                                    onNewCategoryTap()
                                } else {
                                    withAnimation {
                                        selectedCategoryId = "new"
                                    }
                                }
                            }
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
    
    CategorySelector(
        categories: categories,
        selectedCategoryId: $selectedCategoryId,
        onSelectedTap: { _ in },
        onNewCategoryTap: {}
    )
        .onAppear {
            selectedCategoryId = categories.first?.id
        }
}
