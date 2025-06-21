//
//  IxWebSocketClient.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation
import Combine
import SwiftUI
import os

fileprivate let log = Logger(subsystem: IxSubsystems.CORE_KIT, category: "IxWebsocketClient")

public actor IxWebsocketClient {
    private static let wsURL = URL(string: "wss://api.index-it.app/ws")!
    
    private let cookiesStorage: HTTPCookieStorage
    private let ixWebsocketEventHandler: IxWebsocketEventHandler
    
    private var websocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var shouldReconnect = false
    private var reconnectTask: Task<Void, Never>?
    
    private let decoder: JSONDecoder
    
    public init(
        cookiesStorage: HTTPCookieStorage = IxCookieStorageProvider.get(),
        ixWebsocketEventHandler: IxWebsocketEventHandler
    ) {
        self.decoder = IxApiClient.decoder()
        self.cookiesStorage = cookiesStorage
        self.ixWebsocketEventHandler = ixWebsocketEventHandler
        
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = cookiesStorage
        configuration.timeoutIntervalForRequest = 10
        
        // Set user agent
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        configuration.httpAdditionalHeaders = [
            "User-Agent": "iOS \(osVersionString) client"
        ]
        
        urlSession = URLSession(configuration: configuration)
    }
    
    public func connectAndHandleMessages() {
        if websocketTask != nil {
            disconnect()
        }
        
        shouldReconnect = true
        websocketTask = urlSession.webSocketTask(with: Self.wsURL)
        websocketTask?.resume()
        handleMessages()
        
        log.info("Listening to websocket messages")
    }
    
    public func disconnect() {
        shouldReconnect = false
        reconnectTask?.cancel()
        
        websocketTask?.cancel(with: .normalClosure, reason: "Logged out".data(using: .utf8))
        websocketTask = nil
        
        log.info("Disconnected from websocket")
    }
    
    private func handleMessages() {
        guard let websocketTask = websocketTask else {
            // TODO: Report issue
            log.error("websocketTask is nil")
            return
        }
        
        websocketTask.receive { [weak self] result in
            guard let self = self else {
                log.error("IxWebsocketClient instance is nil")
                return
            }
            
            
            // Use Task to bridge to the actor's isolated context
            Task {
                await self.processWebSocketResult(result)
            }
        }
    }
    
    private func processWebSocketResult(_ result: Result<URLSessionWebSocketTask.Message, Error>) async {
        switch result {
        case .success(let message):
            switch message {
            case .string(let text):
                do {
                    let websocketEvent = try self.decoder.decode(WebsocketEventData.self, from: Data(text.utf8))
                    
                    do {
                        try await self.ixWebsocketEventHandler.handleWebsocketEvent(data: websocketEvent)
                    } catch {
                        log.error("Failed handling websocket event: \(error)")
                    }
                } catch {
                    log.error("Failed deserializing websocket message: \(error)")
                }
            case .data(_):
                log.warning("Received binary data from websocket - not supported")
            @unknown default:
                log.warning("Received unknown type of message from websocket")
            }
            
            // Continue receiving messages - now within actor context
            self.handleMessages()
            
        case .failure(let error):
            log.error("WebSocket receive error: \(error)")
            
            if self.shouldReconnect {
                self.scheduleReconnect()
            }
        }
    }
    
    private func scheduleReconnect() {
        reconnectTask?.cancel()
        
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
            if self.shouldReconnect {
                connectAndHandleMessages()
            }
        }
    }
    
    deinit {
        reconnectTask?.cancel()
        websocketTask?.cancel(with: .normalClosure, reason: "Logged out".data(using: .utf8))
    }
}
