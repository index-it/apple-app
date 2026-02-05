//
//  IxListEntityQuery.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

@preconcurrency import AppIntents
import SwiftData
import OSLog

@available(iOS 26.0, *)
struct IxListEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery, EntityPropertyQuery {

    @Dependency
    var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [IxListEntity.ID]) async throws -> [IxListEntity] {
        let descriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                identifiers.contains(list.id)
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxListEntity.init)
    }

    /**
     - Returns: The most likely choices relevant to the individual, such as the contents of a favorites list. The system displays these values as
     a list of options for the entities. For example, configuring the Get Trail Info intent in the Shortcuts app will show these values
     as suggestions for the trail parameter.
     */
    @MainActor
    func suggestedEntities() async throws -> [IxListEntity] {
        let descriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.archived == false
            }
        )

        return try modelContainer.mainContext.fetch(descriptor).map(IxListEntity.init)
    }

    @MainActor
    func entities(matching: String) async throws -> [IxListEntity] {
        let descriptor = FetchDescriptor<IxList>(
            predicate: #Predicate { list in
                list.name.localizedStandardContains(matching)
            }
        )

        return try modelContainer.mainContext.fetch(descriptor).map(IxListEntity.init)
    }

    @MainActor
    func allEntities() async throws -> [IxListEntity] {
        let descriptor = FetchDescriptor<IxList>()
        return try modelContainer.mainContext.fetch(descriptor).map(IxListEntity.init)
    }

    typealias ComparatorMappingType = Predicate<IxListEntity>

    /**
     Declare the entity properties that are available for queries and in the Find intent, along with the comparator the app uses when querying the
     property.
     */
    static let properties = QueryProperties {
        Property(\IxListEntity.$name) {
            ContainsComparator { searchValue in
                #Predicate<IxListEntity> { $0.name.localizedStandardContains(searchValue) }
            }
            EqualToComparator { searchValue in
                #Predicate<IxListEntity> { $0.name == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxListEntity> { $0.name != searchValue }
            }
        }

        Property(\IxListEntity.$color) {
            EqualToComparator { searchValue in
                #Predicate<IxListEntity> { $0.color == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxListEntity> { $0.color != searchValue }
            }
        }

        Property(\IxListEntity.$archived) {
            EqualToComparator { searchValue in
                #Predicate<IxListEntity> { $0.archived == searchValue }
            }
        }
    }

    /// Declare the entity properties available as sort criteria in the Find intent.
    static let sortingOptions = SortingOptions {
        SortableBy(\IxListEntity.$name)
        SortableBy(\IxListEntity.$archived)
    }

    /// The text that people see in the Shortcuts app, describing what this intent does.
    static var findIntentDescription: IntentDescription? {
        IntentDescription(
            "Search for lists based on complex criteria.",
            categoryName: "Lists",
            searchKeywords: ["list"],
            resultValueName: "Lists"
        )
    }

    func entities(
        matching comparators: [Predicate<IxListEntity>],
        mode: ComparatorMode,
        sortedBy: [EntityQuerySort<IxListEntity>],
        limit: Int?
    ) async throws -> [IxListEntity] {
        var fetchDescriptor = FetchDescriptor<IxList>()
        fetchDescriptor.fetchLimit = limit

        var matchedLists = try await MainActor.run { try modelContainer.mainContext
                .fetch(fetchDescriptor)
                .map(IxListEntity.init)
                .compactMap { list in
                    var includeAsResult = mode == .and ? true : false
                    let earlyBreakCondition = includeAsResult

                    for comparator in comparators {
                        guard includeAsResult == earlyBreakCondition else { break }
                        includeAsResult = try comparator.evaluate(list)
                    }

                    return includeAsResult ? list : nil
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
                matchedLists.sort(using: KeyPathComparator(\IxListEntity.name, order: sortOperation.order.sortOrder))
            case \.$archived:
                matchedLists.sort(using: KeyPathComparator(\IxListEntity.archived, order: sortOperation.order.sortOrder))
            default:
                break
            }
        }

        return matchedLists
    }
}
