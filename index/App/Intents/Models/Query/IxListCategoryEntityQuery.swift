//
//  IxListCategoryEntityQuery.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/02/26.
//

@preconcurrency import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct IxListCategoryEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery, EntityPropertyQuery {
    @Dependency
    var modelContainer: ModelContainer
    
    @IntentParameterDependency<CreateItemIntent>(
        \.$list
    )
    var createItemIntent
    
    @IntentParameterDependency<EditItemIntent>(
        \.$list
    )
    var editItemIntent

    @MainActor
    func entities(for identifiers: [IxListCategoryEntity.ID]) async throws -> [IxListCategoryEntity] {
        let descriptor = FetchDescriptor<IxListCategory>(
            predicate: #Predicate { category in
                identifiers.contains(category.id)
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxListCategoryEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [IxListCategoryEntity] {
        if let listId = createItemIntent?.list.id ?? editItemIntent?.list.id {
            let descriptor = FetchDescriptor<IxListCategory>(
                predicate: #Predicate { category in
                    category.listId == listId
                }
            )
            return try modelContainer.mainContext.fetch(descriptor).map(IxListCategoryEntity.init)
        } else {
            let currentTimeMillis = Date.now.currentTimeMillis()
            
            let descriptor = FetchDescriptor<IxListCategory>(
                predicate: #Predicate { category in
                    currentTimeMillis - category.createdAt < 2_592_000_000
                }
            )
            let categories = try modelContainer.mainContext.fetch(descriptor).map(IxListCategoryEntity.init)
            if categories.isEmpty {
                return try modelContainer.mainContext.fetch(FetchDescriptor<IxListCategory>()).map(IxListCategoryEntity.init)
            } else {
                return categories
            }
        }
    }

    @MainActor
    func entities(matching: String) async throws -> [IxListCategoryEntity] {
        let listId = createItemIntent?.list.id ?? editItemIntent?.list.id
        
        let descriptor = FetchDescriptor<IxListCategory>(
            predicate: #Predicate { category in
                (listId == nil || (listId != nil && category.listId == listId!)) &&
                category.name.localizedStandardContains(matching)
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxListCategoryEntity.init)
    }

    @MainActor
    func allEntities() async throws -> [IxListCategoryEntity] {
        let descriptor = if let listId = createItemIntent?.list.id ?? editItemIntent?.list.id {
            FetchDescriptor<IxListCategory>(
                predicate: #Predicate { category in
                    category.listId == listId
                }
            )
        } else {
            FetchDescriptor<IxListCategory>()
        }
        
        return try modelContainer.mainContext.fetch(descriptor).map(IxListCategoryEntity.init)
    }

    typealias ComparatorMappingType = Predicate<IxListCategoryEntity>

    /**
     Declare the entity properties that are available for queries and in the Find intent, along with the comparator the app uses when querying the
     property.
     */
    static let properties = QueryProperties {
        Property(\IxListCategoryEntity.$name) {
            ContainsComparator { searchValue in
                #Predicate<IxListCategoryEntity> { $0.name.localizedStandardContains(searchValue) }
            }
            EqualToComparator { searchValue in
                #Predicate<IxListCategoryEntity> { $0.name == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxListCategoryEntity> { $0.name != searchValue }
            }
        }
    }

    /// Declare the entity properties available as sort criteria in the Find intent.
    static let sortingOptions = SortingOptions {
        SortableBy(\IxListCategoryEntity.$name)
    }

    /// The text that people see in the Shortcuts app, describing what this intent does.
    static var findIntentDescription: IntentDescription? {
        IntentDescription(
            "Search for categories based on complex criteria.",
            categoryName: "Categories",
            searchKeywords: ["category"],
            resultValueName: "Categories"
        )
    }

    func entities(
        matching comparators: [Predicate<IxListCategoryEntity>],
        mode: ComparatorMode,
        sortedBy: [EntityQuerySort<IxListCategoryEntity>],
        limit: Int?
    ) async throws -> [IxListCategoryEntity] {
        var matchedCategories = try await MainActor.run {
            var fetchDescriptor = FetchDescriptor<IxListCategory>()
            fetchDescriptor.fetchLimit = limit
            
            return try modelContainer.mainContext
                .fetch(fetchDescriptor)
                .map(IxListCategoryEntity.init)
                .compactMap { category in
                    var includeAsResult = mode == .and ? true : false
                    let earlyBreakCondition = includeAsResult

                    for comparator in comparators {
                        guard includeAsResult == earlyBreakCondition else { break }
                        includeAsResult = try comparator.evaluate(category)
                    }

                    return includeAsResult ? category : nil
                }
        }

        /**
         Apply the requested sort. `EntityQuerySort` specifies the value to sort by using a `PartialKeyPath`. This key path builds a
         `KeyPathComparator` to use default sorting implementations for the value that the key path provides. For example, this approach uses
         `SortComparator.localizedStandard` when sorting key paths with a `String` value.
         */
        for sortOperation in sortedBy {
            switch sortOperation.by {
            case \.$name:
                matchedCategories.sort(using: KeyPathComparator(\IxListCategoryEntity.name, order: sortOperation.order.sortOrder))
            default:
                break
            }
        }

        return matchedCategories
    }
}
