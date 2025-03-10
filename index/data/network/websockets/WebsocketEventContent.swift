//
//  WebsocketEventContent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

enum WebsocketEventContent: Codable {
    case empty
    case userUpdate(UserUpdateEventContent)
    case categoryCreateOrUpdate(CategoryCreateOrUpdateEventContent)
    case categoryDelete(CategoryDeleteEventContent)
    case itemCreateOrUpdate(ItemCreateOrUpdateEventContent)
    case itemDelete(ItemDeleteEventContent)
    case listCreateOrUpdate(ListCreateOrUpdateEventContent)
    case listDelete(ListDeleteEventContent)
    case taskCreateOrUpdate(TaskCreateOrUpdateEventContent)
    case taskDelete(TaskDeleteEventContent)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "EMPTY":
            self = .empty
        case "USER_UPDATE":
            let payload = try container.decode(UserUpdateEventContent.self, forKey: .payload)
            self = .userUpdate(payload)
        case "CATEGORY_CREATE_OR_UPDATE":
            let payload = try container.decode(CategoryCreateOrUpdateEventContent.self, forKey: .payload)
            self = .categoryCreateOrUpdate(payload)
        case "CATEGORY_DELETE":
            let payload = try container.decode(CategoryDeleteEventContent.self, forKey: .payload)
            self = .categoryDelete(payload)
        case "ITEM_CREATE_OR_UPDATE":
            let payload = try container.decode(ItemCreateOrUpdateEventContent.self, forKey: .payload)
            self = .itemCreateOrUpdate(payload)
        case "ITEM_DELETE":
            let payload = try container.decode(ItemDeleteEventContent.self, forKey: .payload)
            self = .itemDelete(payload)
        case "LIST_CREATE_OR_UPDATE":
            let payload = try container.decode(ListCreateOrUpdateEventContent.self, forKey: .payload)
            self = .listCreateOrUpdate(payload)
        case "LIST_DELETE":
            let payload = try container.decode(ListDeleteEventContent.self, forKey: .payload)
            self = .listDelete(payload)
        case "TASK_CREATE_OR_UPDATE":
            let payload = try container.decode(TaskCreateOrUpdateEventContent.self, forKey: .payload)
            self = .taskCreateOrUpdate(payload)
        case "TASK_DELETE":
            let payload = try container.decode(TaskDeleteEventContent.self, forKey: .payload)
            self = .taskDelete(payload)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown event content type: \(type)"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .empty:
            try container.encode("EMPTY", forKey: .type)
        case .userUpdate(let content):
            try container.encode("USER_UPDATE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .categoryCreateOrUpdate(let content):
            try container.encode("CATEGORY_CREATE_OR_UPDATE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .categoryDelete(let content):
            try container.encode("CATEGORY_DELETE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .itemCreateOrUpdate(let content):
            try container.encode("ITEM_CREATE_OR_UPDATE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .itemDelete(let content):
            try container.encode("ITEM_DELETE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .listCreateOrUpdate(let content):
            try container.encode("LIST_CREATE_OR_UPDATE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .listDelete(let content):
            try container.encode("LIST_DELETE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .taskCreateOrUpdate(let content):
            try container.encode("TASK_CREATE_OR_UPDATE", forKey: .type)
            try container.encode(content, forKey: .payload)
        case .taskDelete(let content):
            try container.encode("TASK_DELETE", forKey: .type)
            try container.encode(content, forKey: .payload)
        }
    }
    
    // Event content types
    struct UserUpdateEventContent: Codable {
        let user: NetworkUser
    }
    
    struct CategoryCreateOrUpdateEventContent: Codable {
        let category: NetworkListCategory
    }
    
    struct CategoryDeleteEventContent: Codable {
        let categoryId: String
    }
    
    struct ItemCreateOrUpdateEventContent: Codable {
        let item: NetworkListItem
    }
    
    struct ItemDeleteEventContent: Codable {
        let itemId: String
    }
    
    struct ListCreateOrUpdateEventContent: Codable {
        let list: NetworkList
    }
    
    struct ListDeleteEventContent: Codable {
        let listId: String
    }
    
    struct TaskCreateOrUpdateEventContent: Codable {
        let task: NetworkTask
    }
    
    struct TaskDeleteEventContent: Codable {
        let taskId: String
    }
}
