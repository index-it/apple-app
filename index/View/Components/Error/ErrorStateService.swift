//
//  ErrorStateService.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 17/11/24.
//

import Foundation
import IxCoreKit
import os

private let log = Logger(subsystem: IxSubsystems.APP, category: "ErrorStateService")

public final class ErrorStateService: ObservableObject {
    @Published public private(set) var alerts: [ErrorAlert] = []

    public init() {}

    public func insert(_ alert: ErrorAlert) {
        #if DEBUG
            log.error("\(alert.underlying)")
        #endif
        remove(id: alert.id)
        alerts.append(alert)
    }

    public func remove(id: ErrorAlert.ID) {
        alerts.removeAll { $0.id == id }
    }

    public func clear() {
        alerts.removeAll()
    }

    public func hasAlert(id: ErrorAlert.ID) -> Bool {
        alerts.contains { $0.id == id }
    }
}
