//
//  ProFeature.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 25/11/24.
//

import SwiftUI

public enum ProFeature: Sendable {
    case public_list
    case unlimited_lists
    case unlimited_task_reminders
    
    public var localizedDescription: String {
        switch self {
        case .public_list:
            return NSLocalizedString("Public lists", comment: "Pro feature: Public lists")
        case .unlimited_lists:
            return NSLocalizedString("Unlimited lists", comment: "Pro feature: Unlimited lists")
        case .unlimited_task_reminders:
            return NSLocalizedString("Unlimited task reminders", comment: "Pro feature: Unlimited task reminders")
        }
    }
}
