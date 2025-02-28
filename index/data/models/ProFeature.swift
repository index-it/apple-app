//
//  ProFeature.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/11/24.
//

import SwiftUI

enum ProFeature {
    case public_list
    case unlimited_lists
    
    var localizedDescription: String {
        switch self {
        case .public_list:
            return NSLocalizedString("Public lists", comment: "Pro feature: Public lists")
        case .unlimited_lists:
            return NSLocalizedString("Unlimited lists", comment: "Pro feature: Unlimited lists")
        }
    }
}
