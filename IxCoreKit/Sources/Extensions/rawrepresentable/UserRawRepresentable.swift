//
//  StorageCodable.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/10/24.
//

import Foundation

extension User: RawRepresentable {
    
    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode(User.self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else { return "" }
        return result
    }
}
