//
//  WidgetHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 07/05/25.
//

import WidgetKit

public actor WidgetHelper {
    public static func reloadTasksWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: IxKinds.todayTasksWidget)
    }
}
