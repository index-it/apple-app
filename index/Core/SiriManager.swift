//
//  SiriManager.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 08/02/26.
//

import Foundation
import Intents
import SwiftUI

@MainActor
class SiriManager: ObservableObject {
    private(set) var permitted = false

    func requestPermissions() {
        INPreferences.requestSiriAuthorization { status in
            switch status {
            case .authorized:
                self.permitted = true
            default:
                self.permitted = false
            }
        }
    }

    func checkForPermissions() {
        let status = INPreferences.siriAuthorizationStatus()

        switch status {
        case .authorized:
            permitted = true
        default:
            permitted = false
        }
    }
}
