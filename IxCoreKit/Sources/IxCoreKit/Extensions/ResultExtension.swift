//
//  ResultExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

public extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
}
