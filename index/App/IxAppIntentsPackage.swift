//
//  IxAppIntentsPackage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import AppIntents
import IxCoreKit

struct IxAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [IxIntentsPackage.self]
    }
}
