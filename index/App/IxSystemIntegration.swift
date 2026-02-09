//
//  IxSystemIntegration.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 06/02/26.
//

import AppIntents
import SwiftData
import IxCoreKit
import CoreSpotlight
import WidgetKit

enum IxSystemIntegration {
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
        WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
    }
    
    static func handleNewEntities<T: IndexedEntity>(_ entities: [T]) async throws {
        try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: entities.map(\.id), ofType: T.self)
        try await CSSearchableIndex.default().indexAppEntities(entities)
        
        if T.self is IxTaskEntity.Type {
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        }
    }
    
    static func handleNewEntity<T: IndexedEntity>(_ entity: T) async throws {
        try await handleNewEntities([entity])
    }

    
    static func handleEntityDeletion<T: IndexedEntity>(_ id: T.ID, of type: T.Type) async throws {
        try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: [id], ofType: T.self)
        
        if T.self == IxTaskEntity.self {
            WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.tasksWidget)
        }
    }
}
