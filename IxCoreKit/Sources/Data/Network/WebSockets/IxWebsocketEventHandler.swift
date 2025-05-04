//
//  IxWebsocketEventHandler.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation
import SwiftData

@MainActor
public class IxWebsocketEventHandler {
    private let ixApiClient: IxApiClient
    private let modelContext: ModelContext
    
    public init(
        ixApiClient: IxApiClient,
        modelContext: ModelContext
    ) {
        self.ixApiClient = ixApiClient
        self.modelContext = modelContext
    }
    
    func handleWebsocketEvent(data: WebsocketEventData) async throws {
        let eventualExceptionMessage = "websocket event content doesn't match type: \(data)"
        
        Task {
            switch data.type {
            case .userAuthSessionsInvalidated:
                try await handleUserAuthSessionsInvalidated()
                
            case .userUpdated:
                switch data.content {
                case .userUpdate(let content):
                    try await handleUserUpdated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .listCreated:
                switch data.content {
                case .listCreateOrUpdate(let content):
                    try await handleListCreated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .listUpdated:
                switch data.content {
                case .listCreateOrUpdate(let content):
                    try await handleListUpdated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .listDeleted:
                switch data.content {
                case .listDelete(let content):
                    try await handleListDeleted(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .categoryCreated:
                switch data.content {
                case .categoryCreateOrUpdate(let content):
                    try await handleCategoryCreated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .categoryUpdated:
                switch data.content {
                case .categoryCreateOrUpdate(let content):
                    try await handleCategoryUpdated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .categoryDeleted:
                switch data.content {
                case .categoryDelete(let content):
                    try await handleCategoryDeleted(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .itemCreated:
                switch data.content {
                case .itemCreateOrUpdate(let content):
                    try await handleItemCreated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .itemUpdated:
                switch data.content {
                case .itemCreateOrUpdate(let content):
                    try await handleItemUpdated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .itemDeleted:
                switch data.content {
                case .itemDelete(let content):
                    try await handleItemDeleted(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .taskCreated:
                switch data.content {
                case .taskCreateOrUpdate(let content):
                    try await handleTaskCreated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .taskUpdated:
                switch data.content {
                case .taskCreateOrUpdate(let content):
                    try await handleTaskUpdated(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
                
            case .taskDeleted:
                switch data.content {
                case .taskDelete(let content):
                    try await handleTaskDeleted(content: content)
                default:
                    throw NSError(domain: "WebsocketEventHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: eventualExceptionMessage])
                }
            }
        }
    }
    
    // MARK: User
    private func handleUserAuthSessionsInvalidated() async throws {
        try await ixApiClient.logout()
    }
    
    private func handleUserUpdated(content: WebsocketEventContent.UserUpdateEventContent) async throws {
        if let encodedData = try? JSONEncoder().encode(User(from: content.user)) {
            UserDefaults.standard.set(encodedData, forKey: AppStorageKeys.loggedInUser)
        }
    }
    
    // MARK: List
    
    private func handleListCreated(content: WebsocketEventContent.ListCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxList(networkList: content.list))
        try modelContext.save()
    }
    
    private func handleListUpdated(content: WebsocketEventContent.ListCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxList(networkList: content.list))
        try modelContext.save()
    }
    
    private func handleListDeleted(content: WebsocketEventContent.ListDeleteEventContent) async throws {
        try modelContext.delete(model: IxList.self, where: #Predicate { list in list.id == content.listId })
        try modelContext.save()
    }
    
    // MARK: Categories
    
    private func handleCategoryCreated(content: WebsocketEventContent.CategoryCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxListCategory(networkListCategory: content.category))
        try modelContext.save()
    }
    
    private func handleCategoryUpdated(content: WebsocketEventContent.CategoryCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxListCategory(networkListCategory: content.category))
        try modelContext.save()
    }
    
    private func handleCategoryDeleted(content: WebsocketEventContent.CategoryDeleteEventContent) async throws {
        try modelContext.delete(model: IxListCategory.self, where: #Predicate { category in category.id == content.categoryId })
        try modelContext.save()
    }
    
    // MARK: Items
    
    private func handleItemCreated(content: WebsocketEventContent.ItemCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxListItem(networkListItem: content.item))
        try modelContext.save()
    }
    
    private func handleItemUpdated(content: WebsocketEventContent.ItemCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxListItem(networkListItem: content.item))
        try modelContext.save()
    }
    
    private func handleItemDeleted(content: WebsocketEventContent.ItemDeleteEventContent) async throws {
        try modelContext.delete(model: IxListItem.self, where: #Predicate { item in item.id == content.itemId })
        try modelContext.save()
    }
    
    // MARK: Tasks
    
    private func handleTaskCreated(content: WebsocketEventContent.TaskCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxTask(networkTask: content.task))
        try modelContext.save()
    }
    
    private func handleTaskUpdated(content: WebsocketEventContent.TaskCreateOrUpdateEventContent) async throws {
        modelContext.insert(IxTask(networkTask: content.task))
        try modelContext.save()
    }
    
    private func handleTaskDeleted(content: WebsocketEventContent.TaskDeleteEventContent) async throws {
        try modelContext.delete(model: IxTask.self, where: #Predicate { task in task.id == content.taskId })
        try modelContext.save()
    }
}
