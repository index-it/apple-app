import Foundation

public struct IxListInvite: Encodable, Decodable, Equatable, Sendable, Sanitizable, Validatable, EmptyInitializable, Identifiable {
    public var id: String
    public var token: String?
    public var listId: String
    public var editor: Bool
    public var maxUsages: Int?
    public var description: String?
    public var expiresAt: Date?
    public var createdAt: Int64

    public init(id: String, token: String?, listId: String, editor: Bool, maxUsages: Int?, description: String?, expiresAt: Date?, createdAt: Int64) {
        self.id = id
        self.token = token
        self.listId = listId
        self.editor = editor
        self.maxUsages = maxUsages
        self.description = description
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    public init(networkListInvite: NetworkListInvite) {
        id = networkListInvite.id
        token = networkListInvite.token
        listId = networkListInvite.listId
        editor = networkListInvite.editor
        maxUsages = networkListInvite.maxUsages
        description = networkListInvite.description
        expiresAt = networkListInvite.expiresAt
        createdAt = networkListInvite.createdAt
    }

    public static func empty() -> IxListInvite {
        return IxListInvite(
            id: "",
            token: "",
            listId: "",
            editor: false,
            maxUsages: 1,
            description: nil,
            expiresAt: nil,
            createdAt: Date.now.currentTimeMillis()
        )
    }

    public var validationRes: Result<Void, ValidationError> {
        if let maxUsages = maxUsages, maxUsages < IxValidations.ListInvite.minMaxUsages || maxUsages > IxValidations.ListInvite.maxMaxUsages {
            return .failure(.init("Max usages must be between \(IxValidations.ListInvite.minMaxUsages) and \(IxValidations.ListInvite.maxMaxUsages)"))
        }

        return .success(())
    }

    public var sanitized: IxListInvite {
        var copy = self

        copy.description = description?.sanitized

        return copy
    }
}
