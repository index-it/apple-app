//
//  SortOrderRawRepresentable.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/05/25.
//

import Foundation

extension SortOrder: @retroactive RawRepresentable {
    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .forward
        case 1:
            self = .reverse
        default:
            return nil
        }
    }

    public var rawValue: Int {
        switch self {
        case .forward:
            return 0
        case .reverse:
            return 1
        }
    }
}
