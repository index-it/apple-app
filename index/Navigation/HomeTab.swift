//
//  HomeTab.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 14/03/25.
//

import SwiftUI

enum HomeTab: Int, CaseIterable, Identifiable, Hashable {
    case tasks = 0
    case lists = 1
    case settings = 2
    
    var id: Int { self.rawValue }
}
