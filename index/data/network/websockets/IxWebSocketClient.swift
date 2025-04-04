//
//  IxWebSocketClient.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation
import Combine
import SwiftUI
//import Starscream

//class IxWebsocketClient: ObservableObject, WebSocketDelegate {
//    private let cookiesStorage: HTTPCookieStorage
//    private let ixWebsocketEventHandler: IxWebsocketEventHandler
//    
//    private var socket: WebSocket!
//    var isConnected = false
//    private var shouldReconnect = false
//    private var reconnectTimer: Timer?
//    
//    private let decoder = JSONDecoder()
//    
//    init(
//        cookiesStorage: HTTPCookieStorage = IxCookieStorageProvider.get(),
//        ixWebsocketEventHandler: IxWebsocketEventHandler
//    ) {
//        self.cookiesStorage = cookiesStorage
//        self.ixWebsocketEventHandler = ixWebsocketEventHandler
//        
//        URLSession.shared.configuration.httpCookieStorage = cookiesStorage
//        var request = URLRequest(url: URL(string: "wss://api.index-it.app/ws")!)
//        request.timeoutInterval = 5
//        socket = WebSocket(request: request)
//        socket.delegate = self
//        socket.connect()
//    }
//    
//    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
//        switch event {
//        case .connected(let headers):
//            isConnected = true
//            print("websocket is connected: \(headers)")
//        case .disconnected(let reason, let code):
//            isConnected = false
//            print("websocket is disconnected: \(reason) with code: \(code)")
//        case .text(let string):
//            print("Received text: \(string)")
//        case .binary(let data):
//            print("Received data: \(data.count)")
//        case .ping(_):
//            break
//        case .pong(_):
//            break
//        case .viabilityChanged(_):
//            break
//        case .reconnectSuggested(_):
//            break
//        case .cancelled:
//            isConnected = false
//        case .error(let error):
//            isConnected = false
//            handleError(error)
//        case .peerClosed:
//            break
//        }
//    }
//    
//    func handleError(_ error: Error?) {
//        if let e = error as? WSError {
//            print("websocket encountered an error: \(e)")
//        } else if let e = error {
//            print("websocket encountered an error: \(e.localizedDescription)")
//        } else {
//            print("websocket encountered an error")
//        }
//    }
//    
//    
//}

class IxWebsocketClient: ObservableObject {
    private let cookiesStorage: HTTPCookieStorage
    private let ixWebsocketEventHandler: IxWebsocketEventHandler
    
    private var websocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var shouldReconnect = false
    private var reconnectTimer: Timer?
    
    private let decoder: JSONDecoder
    
    init(
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
    
    func connectAndListenToWebsocket() {
        if websocketTask != nil {
            disconnectFromWebsocket()
        }
        
        shouldReconnect = true
        
        let wsURL = URL(string: "wss://api.index-it.app/ws")!
        
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
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
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
