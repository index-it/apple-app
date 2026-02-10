//
//  IxSystemIntegration.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/02/26.
//

import AppIntents
import CoreSpotlight
import IxCoreKit
import OSLog
import SwiftData
import WidgetKit

private let log = Logger.systemIntegrationLogger

enum IxDonatableIntent {
    case openTasks
    case openLists
    case openList(IxList)
    case createItem
    case createTask

    var intent: any AppIntent {
        return switch self {
        case .openLists:
            NavigateIntent(navigationOption: .lists)
        case .openTasks:
            NavigateIntent(navigationOption: .tasks)
        case let .openList(list):
            OpenListIntent(target: IxListEntity(list: list))
        case .createItem:
            CreateItemIntent()
        case .createTask:
            CreateTaskIntent()
        }
    }
}

enum IxSystemIntegration {
    static func donateIntent(_ intent: IxDonatableIntent) async {
        do {
            try await IntentDonationManager.shared.donate(intent: intent.intent)
        } catch {
            log.error("Failed donating intent: \(error)")
        }
    }

    @MainActor
    static func donateEntitiesToSpotlight(modelContainer: ModelContainer) async throws {
        let lists = try modelContainer.mainContext.fetch(FetchDescriptor<IxList>()).map(IxListEntity.init)
        let categories = try modelContainer.mainContext.fetch(FetchDescriptor<IxListCategory>()).map(IxListCategoryEntity.init)
        let items = try modelContainer.mainContext.fetch(FetchDescriptor<IxListItem>()).map(IxListItemEntity.init)
        let tasks = try modelContainer.mainContext.fetch(FetchDescriptor<IxTask>()).map(IxTaskEntity.init)

        try await CSSearchableIndex.default().indexAppEntities(lists)
        try await CSSearchableIndex.default().indexAppEntities(categories)
        try await CSSearchableIndex.default().indexAppEntities(items)
        try await CSSearchableIndex.default().indexAppEntities(tasks)
    }

    static func clearEntities() async throws {
        try await CSSearchableIndex.default().deleteAllSearchableItems()
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func handleNewEntities<T: IndexedEntity>(_ entities: [T]) async throws {
        try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: entities.map(\.id), ofType: T.self)
        try await CSSearchableIndex.default().indexAppEntities(entities)

        if T.self is IxTaskEntity.Type {
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.todayTasksWidget)
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.nextTaskWidget)
        } else if T.self is IxListEntity.Type {
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.listsWidget)
        }
    }

    static func handleNewEntity<T: IndexedEntity>(_ entity: T) async throws {
        try await handleNewEntities([entity])
    }

    static func handleEntityDeletion<T: IndexedEntity>(_ id: T.ID, of _: T.Type) async throws {
        try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: [id], ofType: T.self)

        if T.self == IxTaskEntity.self {
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.todayTasksWidget)
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.nextTaskWidget)
        } else if T.self is IxListEntity.Type {
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.listsWidget)
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.listWidget)
        }
    }
}
