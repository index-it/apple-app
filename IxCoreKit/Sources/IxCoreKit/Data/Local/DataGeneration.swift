//
//  DataGeneration.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import SwiftUI
import SwiftData
import os

fileprivate let log = Logger(subsystem: IxSubsystems.CORE_KIT, category: "DataGeneration")

public struct DataGeneration {
    public static let previewListId = UUID().uuidString
    
    @MainActor
    public static func generatePreviewData(modelContext: ModelContext) {
        do {
            let list = IxList.mock(name: "Lenoska", emoji: EmojiHelper.randomEmoji(), color: Color.blue.hexString, id: previewListId)
            
            let categories = [
                IxListCategory.mock(name: "Lavori", color: Color.orange.hexString, listId: list.id, userId: list.userId),
                IxListCategory.mock(name: "Numeri", color: Color.red.hexString, listId: list.id, userId: list.userId),
                IxListCategory.mock(name: "Dotazioni", color: Color.cyan.hexString, listId: list.id, userId: list.userId)
            ]
            
            try modelContext.transaction {
                modelContext.insert(list)
                
                categories.forEach { category in
                    modelContext.insert(category)
                }
            }
        } catch {
            log.error("Failed to generate preview data: \(error)")
        }
    }
}
