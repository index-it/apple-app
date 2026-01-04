//
//  ShareExtensionView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import IxCoreKit

struct ShareExtensionView: View {
    @State private var name: String
    @State private var link: String
    
    init(name: String?, link: String?) {
        self.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.link = link?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    var body: some View {
        QuickAddItemView(
            name: name,
            link: link,
            note: nil,
            selectedListId: nil,
            selectedCategoryId: nil,
            onCancel: close
        )
        .environment(\.ixApiClient, IxApiClient() { _ in })
        .environmentObject(ErrorStateService())
    }

    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close.share.extension"), object: nil)
    }
}

#Preview {
    ShareExtensionView(name: "Think big!", link: nil)
}
