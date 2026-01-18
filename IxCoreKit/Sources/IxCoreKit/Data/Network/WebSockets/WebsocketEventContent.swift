//
//  WebsocketEventContent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

enum WebsocketEventContent: Decodable {
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let contentContainer = try decoder.container(keyedBy: CodingKeys.self)
        let type = try contentContainer.decode(String.self, forKey: .type)

        switch type {
        case "EMPTY":
            self = .empty
        case "USER_UPDATE":
            let payload = try container.decode(UserUpdateEventContent.self)
            self = .userUpdate(payload)
        case "CATEGORY_CREATE_OR_UPDATE":
            let payload = try container.decode(CategoryCreateOrUpdateEventContent.self)
            self = .categoryCreateOrUpdate(payload)
        case "CATEGORY_DELETE":
            let payload = try container.decode(CategoryDeleteEventContent.self)
            self = .categoryDelete(payload)
        case "ITEM_CREATE_OR_UPDATE":
            let payload = try container.decode(ItemCreateOrUpdateEventContent.self)
            self = .itemCreateOrUpdate(payload)
        case "ITEM_DELETE":
            let payload = try container.decode(ItemDeleteEventContent.self)
            self = .itemDelete(payload)
        case "LIST_CREATE_OR_UPDATE":
            let payload = try container.decode(ListCreateOrUpdateEventContent.self)
            self = .listCreateOrUpdate(payload)
        case "LIST_DELETE":
            let payload = try container.decode(ListDeleteEventContent.self)
            self = .listDelete(payload)
        case "TASK_CREATE_OR_UPDATE":
            let payload = try container.decode(TaskCreateOrUpdateEventContent.self)
            self = .taskCreateOrUpdate(payload)
        case "TASK_DELETE":
            let payload = try container.decode(TaskDeleteEventContent.self)
            self = .taskDelete(payload)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: contentContainer,
                debugDescription: "Unknown event content type: \(type)"
            )
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
