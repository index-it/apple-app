//
//  IxWebSocketClient.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation
import Combine
import SwiftUI

class IxWebsocketClient: ObservableObject {
    private let cookiesStorage: HTTPCookieStorage
    private let ixWebsocketEventHandler: IxWebsocketEventHandler
    
    private var websocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var shouldReconnect = false
    private var reconnectTimer: Timer?
    
    private let decoder = JSONDecoder()
    
    init(
        cookiesStorage: HTTPCookieStorage = .shared,
        ixWebsocketEventHandler: IxWebsocketEventHandler
    ) {
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
    
    func connectAndListenToWebsocket() {
        if websocketTask != nil {
            disconnectFromWebsocket()
        }
        
        shouldReconnect = true
        
        var wsURL = URL(string: "wss://api.index-it.app/ws")!
        
        websocketTask = urlSession.webSocketTask(with: wsURL)
        
        print("Connected to websocket")

        receiveMessage()

        websocketTask?.resume()
    }
    
    private func receiveMessage() {
        websocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    do {
                        let websocketEvent = try self.decoder.decode(WebsocketEventData.self, from: Data(text.utf8))
                        print("Received websocket event: \(websocketEvent)")
                        
                        Task {
                            do {
                                try await self.ixWebsocketEventHandler.handleWebsocketEvent(data: websocketEvent)
                            } catch {
                                print("Failed handling websocket event: \(error)")
                            }
                        }
                    } catch {
                        print("Failed deserializing websocket message: \(error)")
                    }
                case .data(_):
                    print("Received binary data from websocket - not supported")
                @unknown default:
                    print("Received unknown type of message from websocket")
                }
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                
                if self.shouldReconnect {
                    self.scheduleReconnect()
                }
            }
        }
    }
    
    private func scheduleReconnect() {
        DispatchQueue.main.async {
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                self?.connectAndListenToWebsocket()
            }
        }
    }
    
    func disconnectFromWebsocket() {
        shouldReconnect = false
        reconnectTimer?.invalidate()
        
        websocketTask?.cancel(with: .normalClosure, reason: "Logged out".data(using: .utf8))
        websocketTask = nil
        
        print("Disconnected from websocket")
    }
    
    deinit {
        disconnectFromWebsocket()
    }
}
