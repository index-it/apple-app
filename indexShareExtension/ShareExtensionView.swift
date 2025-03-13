//
//  ShareExtensionView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI

struct ShareExtensionView: View {
    @State private var name: String
    @State private var link: String
    
    init(name: String?, link: String?) {
        self.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.link = link?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    var body: some View {
        AddListItemFormSheet(
            name: name,
            link: link,
            note: nil,
            selectedListId: nil,
            selectedCategoryId: nil,
            onCancel: close
        )
        .environmentObject(IxApiClient())
    }

    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close.share.extension"), object: nil)
    }
}

#Preview {
    ShareExtensionView(name: "Think big!", link: nil)
}
