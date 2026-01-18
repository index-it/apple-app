//
//  IxApiClientEnvironmentValue.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//

import SwiftUI

public extension EnvironmentValues {
    var ixApiClient: IxApiClient? {
        get { self[IxApiClientKey.self] }
        set { self[IxApiClientKey.self] = newValue }
    }
}
