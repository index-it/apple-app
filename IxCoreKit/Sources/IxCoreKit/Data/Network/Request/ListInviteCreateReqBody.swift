import Foundation

struct ListInviteCreateReqBody: Codable {
    let editor: Bool
    let maxUsages: Int?
    let expiresAt: Date?
    let description: String?
}
