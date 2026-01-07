//
//  CachedFaviconManager.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 07/01/26.
//

import UIKit

public actor CachedFaviconHelper {
    public static let shared = CachedFaviconHelper()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 10 * 1024 * 1024
    }
    
    public func get(for host: String) -> UIImage? {
        return cache.object(forKey: host as NSString)
    }
    
    public func set(_ image: UIImage, for host: String) {
        cache.setObject(image, forKey: host as NSString)
    }
}
