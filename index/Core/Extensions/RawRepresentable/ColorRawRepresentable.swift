//
//  ColorRawRepresentable.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 29/12/24.
//

import SwiftUI

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        self = Color(hexString: rawValue)
    }

    public var rawValue: String {
        return self.hexString
    }
}

extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        
        self.init(hexString: hex)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.hexString)
    } 
}
