//
//  ErrorStateService.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 17/11/24.
//

import Foundation

public final class ErrorStateService: ObservableObject {
    @Published public private(set) var alerts: [ErrorAlert] = []
    
    public init() { }
    
    public func insert(_ alert: ErrorAlert) {
        remove(id: alert.id)
        alerts.append(alert)
    }
    
    public func remove(id: ErrorAlert.ID) {
        alerts.removeAll { $0.id == id }
    }
    
    public func hasAlert(id: ErrorAlert.ID) -> Bool {
        alerts.contains { $0.id == id }
    }
}
