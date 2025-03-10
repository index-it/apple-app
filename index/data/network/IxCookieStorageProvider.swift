//
//  IxCookieStorage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation

struct IxCookieStorageProvider {
    static private let appGroupIdentifier = "group.app.index-it.index"
    
    static func get() -> HTTPCookieStorage {
        return HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: appGroupIdentifier)
    }
}
