//
//  ErrorAlert.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 17/11/24.
//

import Foundation

public struct ErrorAlert: Identifiable {
    public struct Button {
        public let title: String
        
        public let isDestructive: Bool
        
        public let action: () -> Void
        
        public init(title: String, isDestructive: Bool, action: @escaping () -> Void) {
            self.title = title
            self.isDestructive = isDestructive
            self.action = action
        }
    }
    
    public let id: String
    
    public let title: String?
    
    public let message: String
    
    public let underlying: Error?
    
    public let buttons: [Button]
}

public extension ErrorAlert {
    static func localizedError(
        id: String = UUID().uuidString,
        title: String?,
        error: Error,
        buttons: [Button] = []
    ) -> Self {
        .init(
            id: id,
            title: title,
            message: error.localizedDescription,
            underlying: error,
            buttons: buttons
        )
    }
    
    static func customMessageLocalizedError(
        id: String = UUID().uuidString,
        title: String?,
        message: String,
        error: Error,
        buttons: [Button] = []
    ) -> Self {
        .init(
            id: id,
            title: title,
            message: "\(message)\n\n\(error.localizedDescription)",
            underlying: error,
            buttons: buttons
        )
    }
    
    static func customMessage(
        id: String = UUID().uuidString,
        title: String? = nil,
        message: String = "Something went wrong, please try again later",
        underlying: Error? = nil,
        buttons: [Button] = []
    ) -> Self {
        .init(
            id: id,
            title: title,
            message: message,
            underlying: underlying,
            buttons: buttons
        )
    }
}
