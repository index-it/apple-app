//
//  IxCookieStorage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation

public struct IxCookieStorageProvider {
    public static func get() -> HTTPCookieStorage {
        return HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: IxIdentifiers.APP_GROUP)
    }
}
