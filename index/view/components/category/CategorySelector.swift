//
//  CategorySelector.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import SwiftUI
import SwiftData

struct CategorySelector: View {
    @Query private var categories: [IxListCategory]
    
    @Binding private var selectedCategoryId: String?
    @Binding private var selectedCategory: IxListCategory?
    
    private var showUncategorizedItems: Bool
    
    private var onSelectedTap: (_ categoryId: String?) -> ()
    private var onNewCategoryTap: () -> ()
    private var onEdit: (_ category: IxListCategory) -> ()
    private var onDelete: (_ category: IxListCategory) -> ()
    
    init(
        listId: String,
        selectedCategoryId: Binding<String?>,
        selectedCategory: Binding<IxListCategory?>,
        showUncategorizedItems: Bool,
        categorySorting: CategorySorting,
        categoryReverseSorting: Bool,
        onSelectedTap: @escaping (_: String?) -> Void,
        onNewCategoryTap: @escaping () -> Void,
        onEdit: @escaping (_ category: IxListCategory) -> (),
        onDelete: @escaping (_ category: IxListCategory) -> ()
    ) {
        self._selectedCategoryId = selectedCategoryId
        self._selectedCategory = selectedCategory
        self.showUncategorizedItems = showUncategorizedItems
        self.onSelectedTap = onSelectedTap
        self.onNewCategoryTap = onNewCategoryTap
        self.onEdit = onEdit
        self.onDelete = onDelete
        
        let filterPredicate = #Predicate<IxListCategory> { category in
            category.list_id == listId
        }
        
        let sortOrder = if categoryReverseSorting {
            SortOrder.reverse
        } else {
            SortOrder.forward
        }
        
        let sortDescriptor = switch categorySorting {
        case .name:
            SortDescriptor(\IxListCategory.name, order: sortOrder)
        case .creation:
            SortDescriptor(\IxListCategory.created_at, order: sortOrder)
        case .edit:
            SortDescriptor(\IxListCategory.edited_at, order: sortOrder)
        }
       
        _categories = Query(filter: filterPredicate, sort: [sortDescriptor])
    }
    
    
    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollReader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 24) {
                        // MARK: Uncategorized items indicator
                        if showUncategorizedItems {
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
                        }
                        
                        // MARK: Category indicators
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
                                .clipShape(RoundedRectangle(cornerRadius: CategoryUIDefaults.cornerRadius))
                                .contextMenu {
                                    Button("Edit category", systemImage: "square.and.pencil") {
                                        onEdit(category)
                                    }
                                    
                                    Menu {
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                           onDelete(category)
                                        }
                                        
                                        Button("Cancel", role: .cancel) {}
                                    } label: {
                                        Label("Delete category", systemImage: "trash")
                                    }
                                }
                        }
                        
                        // MARK: New category indicator
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
                    .onChange(of: categories, initial: true) { _, newValue in
                        if !showUncategorizedItems && selectedCategoryId == "none" {
                            withAnimation(.snappy(duration: 0.1)) {
                                selectedCategoryId = categories.first?.id ?? "new"
                            }
                        }
                    }
                    .onChange(of: selectedCategoryId, initial: true) { _, newValue in
                        if newValue == "none" || newValue == "new" {
                            selectedCategory = nil
                        } else {
                            selectedCategory = categories.first { $0.id == selectedCategoryId }
                        }
                    }
            }
        }
    }
}

#Preview {
//    @Previewable @State var selectedCategoryId: String? = nil
//    var categories = [IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), ]
//    
//    CategorySelector(
//        categories: categories,
//        selectedCategoryId: $selectedCategoryId,
//        onSelectedTap: { _ in },
//        onNewCategoryTap: {}
//    )
//        .onAppear {
//            selectedCategoryId = categories.first?.id
//        }
}
