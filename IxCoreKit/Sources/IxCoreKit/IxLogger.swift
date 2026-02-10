//
//  IxLogger.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 10/02/26.
//

import OSLog

public extension Logger {
    static let networkLogger = Logger(subsystem: IxSubsystems.CORE_KIT, category: "Network")
    static let websocketLogger = Logger(subsystem: IxSubsystems.CORE_KIT, category: "WebSocket")
    static let dataLogger = Logger(subsystem: IxSubsystems.CORE_KIT, category: "Data")
    
    static let appLogger = Logger(subsystem: IxSubsystems.APP, category: "AppCore")
    static let systemIntegrationLogger = Logger(subsystem: IxSubsystems.APP, category: "SystemIntegration")
    static let uiLogger = Logger(subsystem: IxSubsystems.APP, category: "UI")
    static let intentLogger = Logger(subsystem: IxSubsystems.APP, category: "Intents")
    static let revenueCatLogger = Logger(subsystem: IxSubsystems.APP, category: "RevenueCat")
}
