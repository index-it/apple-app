//
//  CalendarManager.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/02/26.
//

import SwiftUI
import EventKit
import OSLog

private let log = Logger.appLogger

@Observable
class CalendarManager {
    private(set) var store = EKEventStore()
    private(set) var permitted = false
    
    func requestPermissions() async -> Bool {
        do {
            let authorized = try await store.requestFullAccessToEvents()
            if authorized {
                permitted = true
            } else {
                permitted = false
            }
        } catch {
            log.warning("Calendar permission error: \(error)")
            permitted = false
        }
        
        return permitted
    }

    func checkForPermissions() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .fullAccess:
            permitted = true
        default:
            permitted = false
        }
    }
}
