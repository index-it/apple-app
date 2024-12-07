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
                        ForEach(categories) { category in
                            CategoryIndicator(category: category, selected: category.id == selectedCategoryId)
                                .id(category.id)
                        }
                        
                        NewCategoryIndicator(selected: selectedCategoryId == nil)
                            .id("add")
                    }
                    .scrollTargetLayout()
                }.scrollPosition(id: $selectedCategoryId, anchor: .center)
                    .scrollTargetBehavior(.viewAligned)
                    .safeAreaPadding(geoProxy.size.width / 2)
                    .onScrollPhaseChange { oldPhase, newPhase in
                        if !newPhase.isScrolling {
                            withAnimation(.snappy(duration: 0.1)) {
                                scrollReader.scrollTo(selectedCategoryId ?? "add", anchor: .center)
                            }
                        }
                    }
                    .onChange(of: selectedCategoryId) { oldValue, newValue in
                        if newValue == "add" {
                            selectedCategoryId = nil
                        }
                        
                        print("Scrolled to \(selectedCategoryId ?? "nil")")
                    }
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
