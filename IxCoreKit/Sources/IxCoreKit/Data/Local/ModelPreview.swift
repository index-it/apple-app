//
//  ModelPreview.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 12/05/25.
//

import SwiftData
import SwiftUI

public struct ModelPreview<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    var content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ZStack {
            content()
        }
        .modelContainer(ModelContainerProvider.makeModelContainer(isStoredInMemoryOnly: true))
        .onAppear {
            DataGeneration.generatePreviewData(modelContext: modelContext)
        }
    }
}
