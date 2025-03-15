//
//  indexWidgetBundle.swift
//  indexWidget
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import WidgetKit
import SwiftUI

@main
struct indexWidgetBundle: WidgetBundle {
    
    @WidgetBundleBuilder
    var body: some Widget {
        TodayTasksWidget()
        CreateListItemWidgetControl()
        CreateTaskWidgetControl()
    }
}
