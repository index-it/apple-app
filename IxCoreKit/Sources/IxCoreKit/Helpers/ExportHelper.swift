//
//  ExportHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 14/02/26.
//

import Foundation
import SwiftUI

public struct ExportHelper {
    @MainActor
    public static func exportListToPDF(
        list: IxList,
        categoryToItemsMap: [IxListCategory?:[IxListItem]],
        config: ListExportConfig,
        from viewController: UIViewController
    ) {
        let printController = UIPrintInteractionController.shared
        
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "\(list.name)-\(UUID().uuidString)"
        printController.printInfo = info
        
        let renderer = IxListPrintRenderer(
            list: list,
            categoryToItemsMap: categoryToItemsMap,
            config: config
        )
        
        printController.printPageRenderer = renderer
        printController.present(animated: true)
    }
}
