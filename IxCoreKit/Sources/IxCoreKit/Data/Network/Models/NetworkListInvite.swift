import Foundation

public struct NetworkListInvite: Codable, Sendable {
    public let id: String
    public let token: String?
    public let listId: String
    public let editor: Bool
    public let maxUsages: Int?
    public let description: String?
    public let expiresAt: Date?
    public let createdAt: Int64
}
