//
//  ColorRawRepresentable.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import SwiftUI
import Foundation

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        self = Color(hexString: rawValue)
    }

    public var rawValue: String {
        return self.hexString()
    }
}
