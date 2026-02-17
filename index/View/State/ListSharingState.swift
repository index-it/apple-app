//
//  ListSharingState.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 13/02/26.
//


import IxCoreKit
import SwiftUI

@Observable
final class ListSharingState {
    var usersWithAccess: [IxListSingleUserAccessInfo] = []
    var activeInvites: [IxListInvite] = []

    // Sheet + alerts
    var showShareSheet = false
    var showUserInvitationSuccessAlert = false

    // Loading flags
    var loadingPublic = false
    var loadingUsers = false
    var loadingUserInvite = false
    var loadingUserEditOrRevokePermissions: String? = nil

    // Invite creation
    var inviteEditorConfig = EditorConfig<IxListInvite>()
    var inviteUrl: URL? = nil

    func reset() {
        usersWithAccess = []
        activeInvites = []
        loadingPublic = false
        loadingUsers = false
        loadingUserInvite = false
        loadingUserEditOrRevokePermissions = nil
        inviteEditorConfig = EditorConfig<IxListInvite>()
        inviteUrl = nil
    }
}
