//
//  IxListItemEntityQuery.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/02/26.
//

@preconcurrency import AppIntents
import SwiftData
import IxCoreKit

@available(iOS 26.0, *)
struct IxListItemEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery, EntityPropertyQuery {
    @Dependency
    var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [IxListItemEntity.ID]) async throws -> [IxListItemEntity] {
        let descriptor = FetchDescriptor<IxListItem>(
            predicate: #Predicate { item in
                identifiers.contains(item.id)
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxListItemEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [IxListItemEntity] {
        let descriptor = FetchDescriptor<IxListItem>(
            predicate: #Predicate { item in
                item.completed == false
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxListItemEntity.init)
    }

    @MainActor
    func entities(matching: String) async throws -> [IxListItemEntity] {
        let descriptor = FetchDescriptor<IxListItem>(
            predicate: #Predicate { item in
                item.name.localizedStandardContains(matching) || item.note?.localizedStandardContains(matching) == true
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxListItemEntity.init)
    }

    @MainActor
    func allEntities() async throws -> [IxListItemEntity] {
        let descriptor = FetchDescriptor<IxListItem>()
        return try modelContainer.mainContext.fetch(descriptor).map(IxListItemEntity.init)
    }

    typealias ComparatorMappingType = Predicate<IxListItemEntity>

    /**
     Declare the entity properties that are available for queries and in the Find intent, along with the comparator the app uses when querying the
     property.
     */
    static let properties = QueryProperties {
        Property(\IxListItemEntity.$name) {
            ContainsComparator { searchValue in
                #Predicate<IxListItemEntity> { $0.name.localizedStandardContains(searchValue) }
            }
            EqualToComparator { searchValue in
                #Predicate<IxListItemEntity> { $0.name == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxListItemEntity> { $0.name != searchValue }
            }
        }

        Property(\IxListItemEntity.$note) {
            ContainsComparator { searchValue in
                #Predicate<IxListItemEntity> { entity in
                    entity.note != nil && entity.note!.localizedStandardContains(searchValue)
                }
            }
        }

        Property(\IxListItemEntity.$completed) {
            EqualToComparator { searchValue in
                #Predicate<IxListItemEntity> { $0.completed == searchValue }
            }
        }

        Property(\IxListItemEntity.$linkString) {
            ContainsComparator { searchValue in
                #Predicate<IxListItemEntity> { entity in
                    entity.linkString != nil && entity.linkString!.localizedStandardContains(searchValue)
                }
            }
            EqualToComparator { searchValue in
                #Predicate<IxListItemEntity> { entity in
                    entity.linkString != nil && entity.linkString == searchValue
                }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxListItemEntity> { entity in
                    entity.linkString != nil && entity.linkString != searchValue
                }
            }
        }
    }

    /// Declare the entity properties available as sort criteria in the Find intent.
    static let sortingOptions = SortingOptions {
        SortableBy(\IxListItemEntity.$name)
        SortableBy(\IxListItemEntity.$completed)
    }

    /// The text that people see in the Shortcuts app, describing what this intent does.
    static var findIntentDescription: IntentDescription? {
        IntentDescription(
            "Search for items based on complex criteria.",
            categoryName: "Items",
            searchKeywords: ["item", "list item"],
            resultValueName: "Items"
        )
    }

    func entities(
        matching comparators: [Predicate<IxListItemEntity>],
        mode: ComparatorMode,
        sortedBy: [EntityQuerySort<IxListItemEntity>],
        limit: Int?
    ) async throws -> [IxListItemEntity] {
        var matchedItems = try await MainActor.run {
            var fetchDescriptor = FetchDescriptor<IxListItem>()
            fetchDescriptor.fetchLimit = limit
            
            return try modelContainer.mainContext
                .fetch(fetchDescriptor)
                .map(IxListItemEntity.init)
                .compactMap { item in
                    var includeAsResult = mode == .and ? true : false
                    let earlyBreakCondition = includeAsResult

                    for comparator in comparators {
                        guard includeAsResult == earlyBreakCondition else { break }
                        includeAsResult = try comparator.evaluate(item)
                    }

                    return includeAsResult ? item : nil
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
                matchedItems.sort(using: KeyPathComparator(\IxListItemEntity.name, order: sortOperation.order.sortOrder))
            case \.$completed:
                matchedItems.sort(using: KeyPathComparator(\IxListItemEntity.completed, order: sortOperation.order.sortOrder))
            default:
                break
            }
        }

        return matchedItems
    }
}
