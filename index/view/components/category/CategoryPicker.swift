//
//  CategorySelector.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 07/12/24.
//
import SwiftUI
import SwiftData

struct CategoryPicker: View {
    @Query private var categories: [IxListCategory]
    
    @Binding private var selectedCategory: IxListCategory?
    private var hideDefaultCategory: Bool
    
    private var onCreate: () -> Void
    private var onEdit: (_ category: IxListCategory) -> Void
    private var onDelete: (_ category: IxListCategory) -> Void
    
    init(
        listId: String,
        selectedCategory: Binding<IxListCategory?>,
        categorySorting: CategorySorting,
        categoryReverseSorting: Bool,
        hideDefaultCategory: Bool,
        onCreate: @escaping () -> Void,
        onEdit: @escaping (_ category: IxListCategory) -> Void,
        onDelete: @escaping (_ category: IxListCategory) -> Void
    ) {
        self._selectedCategory = selectedCategory
        self.hideDefaultCategory = hideDefaultCategory
        self.onCreate = onCreate
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
        Menu {
            Section {
                if let selectedCategory = selectedCategory {
                    Menu {
                        Button("Cancel", role: .cancel) {}
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onDelete(selectedCategory)
                        }
                    } label: {
                        Label("Delete category", systemImage: "trash")
                    }
                    
                    Button("Edit category", systemImage: "square.and.pencil") {
                        onEdit(selectedCategory)
                    }
                }
                
                Button("Create category", systemImage: "plus") {
                    onCreate()
                }
            }
            
            ForEach(categories) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                        }
                        
                        Text(category.name)
                    }
                }
            }
            
            if !hideDefaultCategory {
                Button {
                    selectedCategory = nil
                } label: {
                    HStack {
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                        }
                        
                        Text("Default")
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedCategory?.name.prefix(20) ?? "Default")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
            }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(UIColor.secondarySystemFill.toColor())
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }.onChange(of: categories, initial: true) { _, newCategories in
            if hideDefaultCategory && selectedCategory == nil {
                selectedCategory = newCategories.first
            }
        }.onChange(of: hideDefaultCategory) { _, newValue in
            if newValue && selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }
}

#Preview {
    CategoryPicker(
        listId: "",
        selectedCategory: .constant(nil),
        categorySorting: .name,
        categoryReverseSorting: false,
        hideDefaultCategory: false
    ) {
        
    } onEdit: { category in
        
    } onDelete: { category in
        
    }
}

//struct CategorySelector: View {
//    @Query private var categories: [IxListCategory]
//    
//    @Binding private var selectedCategoryId: String?
//    @Binding private var selectedCategory: IxListCategory?
//    @Binding private var previousCategory: IxListCategory?
//    @Binding private var nextCategory: IxListCategory?
//    
//    private var showUncategorizedItems: Bool
//    
//    private var onSelectedTap: (_ categoryId: String?) -> ()
//    private var onHideUncategorized: () -> ()
//    private var onNewCategoryTap: () -> ()
//    private var onEdit: (_ category: IxListCategory) -> ()
//    private var onDelete: (_ category: IxListCategory) -> ()
//    
//    init(
//        listId: String,
//        selectedCategoryId: Binding<String?>,
//        selectedCategory: Binding<IxListCategory?>,
//        previousCategory: Binding<IxListCategory?>,
//        nextCategory: Binding<IxListCategory?>,
//        showUncategorizedItems: Bool,
//        categorySorting: CategorySorting,
//        categoryReverseSorting: Bool,
//        onSelectedTap: @escaping (_: String?) -> Void,
//        onHideUncategorized: @escaping () -> (),
//        onNewCategoryTap: @escaping () -> Void,
//        onEdit: @escaping (_ category: IxListCategory) -> (),
//        onDelete: @escaping (_ category: IxListCategory) -> ()
//    ) {
//        self._selectedCategoryId = selectedCategoryId
//        self._selectedCategory = selectedCategory
//        self._previousCategory = previousCategory
//        self._nextCategory = nextCategory
//        self.showUncategorizedItems = showUncategorizedItems
//        self.onSelectedTap = onSelectedTap
//        self.onHideUncategorized = onHideUncategorized
//        self.onNewCategoryTap = onNewCategoryTap
//        self.onEdit = onEdit
//        self.onDelete = onDelete
//        
//        let filterPredicate = #Predicate<IxListCategory> { category in
//            category.list_id == listId
//        }
//        
//        let sortOrder = if categoryReverseSorting {
//            SortOrder.reverse
//        } else {
//            SortOrder.forward
//        }
//        
//        let sortDescriptor = switch categorySorting {
//        case .name:
//            SortDescriptor(\IxListCategory.name, order: sortOrder)
//        case .creation:
//            SortDescriptor(\IxListCategory.created_at, order: sortOrder)
//        case .edit:
//            SortDescriptor(\IxListCategory.edited_at, order: sortOrder)
//        }
//       
//        _categories = Query(filter: filterPredicate, sort: [sortDescriptor])
//    }
//    
//    
//    var body: some View {
//        GeometryReader { geoProxy in
//            ScrollViewReader { scrollReader in
//                ScrollView(.horizontal, showsIndicators: false) {
//                    LazyHStack(spacing: 24) {
//                        // MARK: Uncategorized items indicator
//                        if showUncategorizedItems {
//                            NoCategoryIndicator(selected: selectedCategoryId == "none")
//                                .id("none")
//                                .scrollTransition(axis: .horizontal) { content, phase in
//                                    content
//                                        .scaleEffect(
//                                            x: phase.isIdentity ? 1.75 : 1,
//                                            y: phase.isIdentity ? 1.75 : 1
//                                        )
//                                }
//                                .onTapGesture {
//                                    if selectedCategoryId == "none" {
//                                        onSelectedTap(nil)
//                                    } else {
//                                        withAnimation {
//                                            selectedCategoryId = "none"
//                                        }
//                                    }
//                                }
//                                .contextMenu {
//                                    Button("Hide default category", systemImage: "eye.slash") {
//                                        onHideUncategorized()
//                                    }
//                                }
//                        }
//                        
//                        // MARK: Category indicators
//                        ForEach(categories) { category in
//                            CategoryIndicator(category: category, selected: category.id == selectedCategoryId)
//                                .id(category.id)
//                                .scrollTransition(axis: .horizontal) { content, phase in
//                                    content
//                                        .scaleEffect(
//                                            x: phase.isIdentity ? 1.75 : 1,
//                                            y: phase.isIdentity ? 1.75 : 1
//                                        )
//                                }
//                                .onTapGesture {
//                                    if category.id == selectedCategoryId {
//                                        onSelectedTap(category.id)
//                                    } else {
//                                        withAnimation {
//                                            selectedCategoryId = category.id
//                                        }
//                                    }
//                                }
//                                .contextMenu {
//                                    Section {
//                                        Picker(selection: $selectedCategoryId.animation(), label: Text("Select category")) {
//                                            ForEach(categories) { category in
//                                                Text(category.name)
//                                                    .tag(category.id)
//                                            }
//                                        }
//                                    }
//                                    
//                                    Button("Edit category", systemImage: "square.and.pencil") {
//                                        onEdit(category)
//                                    }
//                                    
//                                    Menu {
//                                        Button("Delete", systemImage: "trash", role: .destructive) {
//                                           onDelete(category)
//                                        }
//                                        
//                                        Button("Cancel", role: .cancel) {}
//                                    } label: {
//                                        Label("Delete category", systemImage: "trash")
//                                    }
//                                }
//                        }
//                        
//                        // MARK: New category indicator
//                        NewCategoryIndicator(selected: selectedCategoryId == "new")
//                            .id("new")
//                            .scrollTransition(axis: .horizontal) { content, phase in
//                                content
//                                    .scaleEffect(
//                                        x: phase.isIdentity ? 1.75 : 1,
//                                        y: phase.isIdentity ? 1.75 : 1
//                                    )
//                            }
//                            .onTapGesture {
//                                if selectedCategoryId == "new" {
//                                    onNewCategoryTap()
//                                } else {
//                                    withAnimation {
//                                        selectedCategoryId = "new"
//                                    }
//                                }
//                            }
//                    }
//                    .scrollTargetLayout()
//                    .fixedSize(horizontal: false, vertical: true)
//                    .frame(height: CategoryUIDefaults.height + 48)
//                }.scrollPosition(id: $selectedCategoryId, anchor: .center)
//                    .scrollTargetBehavior(.viewAligned)
//                    .safeAreaPadding(geoProxy.size.width / 2)
//                    .onScrollPhaseChange { oldPhase, newPhase in
//                        if !newPhase.isScrolling {
//                            withAnimation(.snappy(duration: 0.1)) {
//                                scrollReader.scrollTo(selectedCategoryId, anchor: .center)
//                            }
//                        }
//                    }
//                    .frame(height: CategoryUIDefaults.height + 48)
//                    .onChange(of: categories, initial: true) { _, newValue in
//                        if !showUncategorizedItems && selectedCategoryId == "none" {
//                            withAnimation(.snappy(duration: 0.1)) {
//                                selectedCategoryId = categories.first?.id ?? "new"
//                            }
//                        }
//                    }
//                    .onChange(of: showUncategorizedItems) { _, _ in
//                        if !showUncategorizedItems && selectedCategoryId == "none" {
//                            withAnimation {
//                                selectedCategoryId = categories.first?.id ?? "new"
//                            }
//                        } else {
//                            withAnimation {
//                                scrollReader.scrollTo(selectedCategoryId, anchor: .center)
//                            }
//                        }
//                    }
//                    .onChange(of: selectedCategoryId, initial: true) { _, newValue in
//                        if newValue == "none" {
//                            selectedCategory = nil
//                            previousCategory = nil
//                            nextCategory = categories.first
//                        } else if newValue == "new" {
//                            selectedCategory = nil
//                            previousCategory = categories.last
//                            nextCategory = nil
//                        } else {
//                            guard let selectedCategoryIndex = categories.firstIndex(where: { $0.id == selectedCategoryId }) else { return }
//                            selectedCategory = categories.first { $0.id == selectedCategoryId }
//                            
//                            if selectedCategoryIndex - 1 >= 0 {
//                                previousCategory = categories[selectedCategoryIndex - 1]
//                            } else {
//                                previousCategory = nil
//                            }
//                            
//                            if selectedCategoryIndex + 1 < categories.count {
//                                nextCategory = categories[selectedCategoryIndex + 1]
//                            } else {
//                                nextCategory = nil
//                            }
//                        }
//                    }
//                    .sensoryFeedback(.selection, trigger: selectedCategoryId)
//            }
//        }
//    }
//}
//
//#Preview {
////    @Previewable @State var selectedCategoryId: String? = nil
////    var categories = [IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), IxListCategory.loading(), ]
////    
////    CategorySelector(
////        categories: categories,
////        selectedCategoryId: $selectedCategoryId,
////        onSelectedTap: { _ in },
////        onNewCategoryTap: {}
////    )
////        .onAppear {
////            selectedCategoryId = categories.first?.id
////        }
//}
