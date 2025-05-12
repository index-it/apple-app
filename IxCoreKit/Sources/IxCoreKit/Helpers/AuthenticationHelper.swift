//
//  AuthenticationHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import SwiftUI

@MainActor
public class AuthenticationHelper: ObservableObject {
    @Published public private(set) var backendAuthStatus: AuthStatus
    @Published public private(set) var localAuthStatus: AuthStatus
    
    public init() {
        self.backendAuthStatus = .loading
        self.localAuthStatus = .loading
    }
    
    public func setBackendAuthStatus(_ status: AuthStatus) {
        self.backendAuthStatus = status
    }
    
    public func setLocalAuthStatus(_ status: AuthStatus) {
        self.localAuthStatus = status
    }
}
