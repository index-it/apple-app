//
//  URLExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 20/01/26.
//

import Foundation

extension URL: Identifiable {
    public var id: String { self.absoluteString }
}
