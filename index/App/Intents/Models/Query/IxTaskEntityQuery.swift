//
//  IxTaskEntityQuery.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/02/26.
//

@preconcurrency import AppIntents
import IxCoreKit
import SwiftData

@available(iOS 26.0, *)
struct IxTaskEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery, EntityPropertyQuery {
    @Dependency
    var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [IxTaskEntity.ID]) async throws -> [IxTaskEntity] {
        let descriptor = FetchDescriptor<IxTask>(
            predicate: #Predicate { task in
                identifiers.contains(task.id)
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxTaskEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [IxTaskEntity] {
        let now = Date.now
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let descriptor = FetchDescriptor<IxTask>(
            predicate: #Predicate { task in
                task.completed == false && (task.dueDate == nil || task.dueDate! <= sevenDaysFromNow)
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxTaskEntity.init)
    }

    @MainActor
    func entities(matching: String) async throws -> [IxTaskEntity] {
        let descriptor = FetchDescriptor<IxTask>(
            predicate: #Predicate { task in
                task.name.localizedStandardContains(matching) || task.taskDescription?.localizedStandardContains(matching) == true
            }
        )
        return try modelContainer.mainContext.fetch(descriptor).map(IxTaskEntity.init)
    }

    @MainActor
    func allEntities() async throws -> [IxTaskEntity] {
        let descriptor = FetchDescriptor<IxTask>()
        return try modelContainer.mainContext.fetch(descriptor).map(IxTaskEntity.init)
    }

    typealias ComparatorMappingType = Predicate<IxTaskEntity>

    /**
     Declare the entity properties that are available for queries and in the Find intent, along with the comparator the app uses when querying the
     property.
     */
    static let properties = QueryProperties {
        Property(\IxTaskEntity.$name) {
            ContainsComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.name.localizedStandardContains(searchValue) }
            }
            EqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.name == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.name != searchValue }
            }
        }

        Property(\IxTaskEntity.$description) {
            ContainsComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.description.localizedStandardContains(searchValue) }
            }
        }

        Property(\IxTaskEntity.$completed) {
            EqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.completed == searchValue }
            }
        }

        Property(\IxTaskEntity.$priority) {
            EqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.priority == searchValue }
            }
            NotEqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.priority != searchValue }
            }
            LessThanOrEqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { entity in
                    entity.priority != nil && entity.priority! <= searchValue
                }
            }
            GreaterThanOrEqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { entity in
                    entity.priority != nil && entity.priority! >= searchValue
                }
            }
        }

        Property(\IxTaskEntity.$dueDate) {
            EqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { $0.dueDate == searchValue }
            }
            LessThanOrEqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { entity in
                    entity.dueDate != nil && entity.dueDate! <= searchValue
                }
            }
            GreaterThanOrEqualToComparator { searchValue in
                #Predicate<IxTaskEntity> { entity in
                    entity.dueDate != nil && entity.dueDate! >= searchValue
                }
            }
        }
    }

    /// Declare the entity properties available as sort criteria in the Find intent.
    static let sortingOptions = SortingOptions {
        SortableBy(\IxTaskEntity.$name)
        SortableBy(\IxTaskEntity.$priority)
        SortableBy(\IxTaskEntity.$dueDate)
        SortableBy(\IxTaskEntity.$completed)
    }

    /// The text that people see in the Shortcuts app, describing what this intent does.
    static var findIntentDescription: IntentDescription? {
        IntentDescription(
            "Search for tasks based on complex criteria.",
            categoryName: "Tasks",
            searchKeywords: ["task", "todo", "to-do", "reminder"],
            resultValueName: "Tasks"
        )
    }

    func entities(
        matching comparators: [Predicate<IxTaskEntity>],
        mode: ComparatorMode,
        sortedBy: [EntityQuerySort<IxTaskEntity>],
        limit: Int?
    ) async throws -> [IxTaskEntity] {
        var matchedTasks = try await MainActor.run {
            var fetchDescriptor = FetchDescriptor<IxTask>()
            fetchDescriptor.fetchLimit = limit

            return try modelContainer.mainContext
                .fetch(fetchDescriptor)
                .map(IxTaskEntity.init)
                .compactMap { task in
                    var includeAsResult = mode == .and ? true : false
                    let earlyBreakCondition = includeAsResult

                    for comparator in comparators {
                        guard includeAsResult == earlyBreakCondition else { break }
                        includeAsResult = try comparator.evaluate(task)
                    }

                    return includeAsResult ? task : nil
                }
        }

        /* 
         Apply the requested sort. `EntityQuerySort` specifies the value to sort by using a `PartialKeyPath`. This key path builds a
         `KeyPathComparator` to use default sorting implementations for the value that the key path provides. For example, this approach uses
         `SortComparator.localizedStandard` when sorting key paths with a `String` value.
         */
        for sortOperation in sortedBy {
            switch sortOperation.by {
            case \.$name:
                matchedTasks.sort(using: KeyPathComparator(\IxTaskEntity.name, order: sortOperation.order.sortOrder))
            case \.$priority:
                matchedTasks.sort(using: KeyPathComparator(\IxTaskEntity.priority, order: sortOperation.order.sortOrder))
            case \.$completed:
                matchedTasks.sort(using: KeyPathComparator(\IxTaskEntity.completed, order: sortOperation.order.sortOrder))
            case \.$dueDate:
                matchedTasks.sort(using: KeyPathComparator(\IxTaskEntity.dueDate, order: sortOperation.order.sortOrder))
            default:
                break
            }
        }

        return matchedTasks
    }
}
